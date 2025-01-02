#!/bin/sh

# Set constants
ROOT_TOKEN_LINE=5
NON_ROOT_TOKEN_LINE=6
TOTAL_LINES_IN_FILE=6
SECRETS_PATH="secret"
SSH_KEY_POLICY_NAME="ssh_key_policy"
SSH_KEYS_DIR="${SECRETS_PATH}/ssh_keys"
SSH_KEY_POLICY_PATH="/vault/policies/ssh_key_policy.hcl"

. /opt/vault/common.sh

terminate_vault() {
  log "Terminating Vault server..."
  kill $VAULT_PID
  wait $VAULT_PID 2>/dev/null
  log "Vault server terminated."
}

trap terminate_vault INT TERM EXIT

# Start Vault server in the background
log "Starting Vault server..."
if [ "$SERVER_MODE" = "prod" ]; then
  export VAULT_EXTERNAL_PORT=8200
  sed "s|\${VAULT_EXTERNAL_PORT}|$VAULT_EXTERNAL_PORT|g" /vault/config/vault_config.hcl > /vault/config/vault_config_substituted.hcl
  vault server -config=/vault/config/vault_config_substituted.hcl &
else
  export VAULT_EXTERNAL_PORT=8300
  sed "s|\${VAULT_EXTERNAL_PORT}|$VAULT_EXTERNAL_PORT|g" /vault/config/vault_config.hcl > /vault/config/vault_config_substituted.hcl
  vault server -dev -config=/vault/config/vault_config_substituted.hcl &
fi
VAULT_PID=$!  # Capture the process ID of the Vault server

if [ -z "$ENVIRONMENT" ]; then
  log "Error: ENVIRONMENT variable is not set. Please set it before running the script."
  exit 1
fi

log "Waiting for Vault to be ready..."
check_vault_status "200 OK|initialized"
log "Vault is ready."

generate_and_store_keypair() {
  MACHINE_NAME=$1
  KEYS_DIR=$2
  if ! vault kv get "${KEYS_DIR}" > /dev/null 2>&1; then
    log "Generating keys for ${MACHINE_NAME}..."
    ssh-keygen -t rsa -b 2048 -f "/tmp/${MACHINE_NAME}_id_rsa" -N ""
    if vault kv put "${KEYS_DIR}" \
      id_rsa=@"/tmp/${MACHINE_NAME}_id_rsa" \
      id_rsa.pub=@"/tmp/${MACHINE_NAME}_id_rsa.pub"; then
      log "SSH keys for ${MACHINE_NAME} have been stored in Vault!"
      rm -f "/tmp/${MACHINE_NAME}_id_rsa" "/tmp/${MACHINE_NAME}_id_rsa.pub"
    else
      log "Failed to store SSH keys for ${MACHINE_NAME}."
      rm -f "/tmp/${MACHINE_NAME}_id_rsa" "/tmp/${MACHINE_NAME}_id_rsa.pub"
      exit 1
    fi
  else
    log "Keys for ${MACHINE_NAME} already exist in Vault."
  fi
}

if [ "$SERVER_MODE" = "prod" ]; then
  log "Unsealing Vault..."
  sh /opt/vault/unseal.sh

  log "Logging in as root token..."
  login_with_token "${ROOT_TOKEN_LINE}p"

  log "Enabling Secrets Engine at path=${SECRETS_PATH}..."
  if vault read "sys/mounts/${SECRETS_PATH}" > /dev/null 2>&1; then
    log "Secrets engine at path=${SECRETS_PATH} is already enabled. Skipping..."
  else
    if ! vault secrets enable -path="${SECRETS_PATH}" kv-v2; then
      log "Error: Failed to enable secrets engine at path=${SECRETS_PATH}. Exiting..."
      exit 1
    fi
    log "Secrets engine at path=${SECRETS_PATH} has been enabled."
  fi
else
  touch "$KEYS_FILE"
  while [ "$(wc -l < "$KEYS_FILE")" -lt $TOTAL_LINES_IN_FILE ]; do
    echo "" >> "$KEYS_FILE"
  done
  sed -i "${ROOT_TOKEN_LINE}c\Non-root token: $VAULT_DEV_ROOT_TOKEN_ID" "$KEYS_FILE"

  log "Logging in as root token..."
  login_with_token "${ROOT_TOKEN_LINE}p"
fi

log "Applying Vault policy..."
if vault policy read ${SSH_KEY_POLICY_NAME} > /dev/null 2>&1; then
  log "Vault policy '${SSH_KEY_POLICY_NAME}' already exists. Skipping policy application..."
else
  if ! vault policy write ${SSH_KEY_POLICY_NAME} ${SSH_KEY_POLICY_PATH}; then
    log "Error: Failed to apply Vault policy. Exiting..."
    exit 1
  else
    log "Vault policy '${SSH_KEY_POLICY_NAME}' applied successfully."
  fi
fi

vault policy read ${SSH_KEY_POLICY_NAME}

log "Creating non-root token with ${SSH_KEY_POLICY_NAME} policy..."
NON_ROOT_TOKEN=$(vault token create -policy="${SSH_KEY_POLICY_NAME}" \
                                    -format=json \
                                    | grep '"client_token"' \
                                    | sed 's/.*"client_token": "\(.*\)",/\1/')

if [ -z "$NON_ROOT_TOKEN" ]; then
  log "Error: Failed to create non-root token."
  exit 1
fi

MASKED_NON_ROOT_TOKEN=$(echo "$NON_ROOT_TOKEN" | sed 's/^\(....\).*/\1****/')
log "Non-root token created: $MASKED_NON_ROOT_TOKEN"

if ! sed -i "${NON_ROOT_TOKEN_LINE}c\Non-root token: $NON_ROOT_TOKEN" "$KEYS_FILE"; then
  log "Error: Failed to update $KEYS_FILE with the non-root token."
  exit 1
fi
log "Non-root token has been saved."

log "Logging in as non-root token..."
login_with_token "${NON_ROOT_TOKEN_LINE}p"

generate_and_store_keypair "ansible" "${SSH_KEYS_DIR}/ansible"
generate_and_store_keypair "linux_ssh_keys_host" "${SSH_KEYS_DIR}/${ENVIRONMENT}/linux_ssh_keys_host"

wait $VAULT_PID
