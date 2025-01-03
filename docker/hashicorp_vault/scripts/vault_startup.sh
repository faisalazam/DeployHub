#!/bin/sh

NON_ROOT_TOKEN_LINE=6
SECRETS_PATH="secret"
SSH_KEYS_DIR="${SECRETS_PATH}/ssh_keys"

. /opt/vault/common.sh

terminate_vault() {
  if [ -n "$VAULT_PID" ]; then
    log "Terminating Vault server..."
    kill $VAULT_PID
    wait $VAULT_PID 2>/dev/null
    log "Vault server terminated."
  else
    log "Vault server was not running."
  fi
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
  log "ENVIRONMENT variable is not set. Please set it before running the script." "ERROR"
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

log "Configuring Vault Environment..."
sh /opt/vault/vault_configure.sh

log "Create Service Account/Token with Vault Policy..."
sh /opt/vault/create_svc_token_with_policy.sh

log "Logging in as non-root token..."
login_with_token "${NON_ROOT_TOKEN_LINE}p"

generate_and_store_keypair "ansible" "${SSH_KEYS_DIR}/ansible"
generate_and_store_keypair "linux_ssh_keys_host" "${SSH_KEYS_DIR}/${ENVIRONMENT}/linux_ssh_keys_host"

wait $VAULT_PID
