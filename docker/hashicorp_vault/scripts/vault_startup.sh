#!/bin/sh

. /opt/vault/common.sh

# Start Vault server in the background
echo "Starting Vault server..."
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

# Ensure ENVIRONMENT variable is set
if [ -z "$ENVIRONMENT" ]; then
  echo "Error: ENVIRONMENT variable is not set. Please set it before running the script."
  exit 1
fi

echo "Waiting for Vault to be ready..."
check_vault_status "200 OK|initialized"
echo "Vault is ready."

SECRETS_PATH="secret"
SSH_KEYS_DIR="${SECRETS_PATH}/ssh_keys"

generate_and_store_keypair() {
  MACHINE_NAME=$1
  KEYS_DIR=$2

  # Check if keys already exist
  if ! vault kv get "${KEYS_DIR}" > /dev/null 2>&1; then
    echo "Generating keys for ${MACHINE_NAME}..."
    ssh-keygen -t rsa -b 2048 -f "/tmp/${MACHINE_NAME}_id_rsa" -N ""
    if vault kv put "${KEYS_DIR}" \
      id_rsa=@"/tmp/${MACHINE_NAME}_id_rsa" \
      id_rsa.pub=@"/tmp/${MACHINE_NAME}_id_rsa.pub"; then
      echo "SSH keys for ${MACHINE_NAME} have been stored in Vault!"
      rm -f "/tmp/${MACHINE_NAME}_id_rsa" "/tmp/${MACHINE_NAME}_id_rsa.pub"
    else
      echo "Failed to store SSH keys for ${MACHINE_NAME}."
      rm -f "/tmp/${MACHINE_NAME}_id_rsa" "/tmp/${MACHINE_NAME}_id_rsa.pub"
      exit 1
    fi
  else
    echo "Keys for ${MACHINE_NAME} already exist in Vault."
  fi
}

if [ "$SERVER_MODE" = "prod" ]; then
  echo "Unsealing Vault..."
  if ! sh /opt/vault/unseal.sh; then
    echo "Error: Failed to unseal Vault. Exiting."
    exit 1
  fi

  echo "Enabling Secrets Engine at path=${SECRETS_PATH}..."
  if ! vault secrets enable -path="${SECRETS_PATH}" kv-v2; then
    echo "Error: Failed to enable secrets engine at path=${SECRETS_PATH}. Exiting..."
    exit 1
  fi
fi

echo "Applying Vault policy..."
SSH_KEY_POLICY_NAME="ssh_key_policy"
SSH_KEY_POLICY_PATH="/vault/policies/ssh_key_policy.hcl"

# Check if the policy already exists
if vault policy read ${SSH_KEY_POLICY_NAME} > /dev/null 2>&1; then
  echo "Vault policy '${SSH_KEY_POLICY_NAME}' already exists. Skipping policy application..."
else
  # Apply the policy if it doesn't exist
  if ! vault policy write ${SSH_KEY_POLICY_NAME} ${SSH_KEY_POLICY_PATH}; then
    echo "Error: Failed to apply Vault policy. Exiting..."
    exit 1
  else
    echo "Vault policy '${SSH_KEY_POLICY_NAME}' applied successfully."
  fi
fi

# Read and display the policy
vault policy read ${SSH_KEY_POLICY_NAME}

echo "Creating non-root token with ${SSH_KEY_POLICY_NAME} policy..."
NON_ROOT_TOKEN=$(vault token create -policy="${SSH_KEY_POLICY_NAME}" \
                                    -format=json \
                                    | grep '"client_token"' \
                                    | sed 's/.*"client_token": "\(.*\)",/\1/')
# Save the non-root token for later use
echo "Non-root token: $NON_ROOT_TOKEN"
echo "Non-root token: $NON_ROOT_TOKEN" >> "$KEYS_FILE"

# Display message
echo "Non-root token has been created and saved."

# Login as non-root token
login_with_token '6p'

# Generate keys for Ansible (environment-agnostic)
generate_and_store_keypair "ansible" "${SSH_KEYS_DIR}/ansible"

# Generate keys for remote hosts (environment-specific)
generate_and_store_keypair "linux_ssh_keys_host" "${SSH_KEYS_DIR}/${ENVIRONMENT}/linux_ssh_keys_host"

# Bring the Vault server process to the foreground
wait $VAULT_PID
