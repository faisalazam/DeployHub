#!/bin/sh

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

# Timeout settings
RETRY_COUNT=0
MAX_RETRIES=10
RETRY_INTERVAL=1

# Ensure ENVIRONMENT variable is set
if [ -z "$ENVIRONMENT" ]; then
  echo "Error: ENVIRONMENT variable is not set. Please set it before running the script."
  exit 1
fi

# Wait for Vault to be ready
echo "Waiting for Vault to be ready..."
until printf 'GET /v1/sys/health HTTP/1.1\r\nHost: localhost\r\n\r\n' \
              | nc -w 5 127.0.0.1 8200 \
              | grep -E '200 OK|initialized' > /dev/null 2>&1; do
  # Check if we've exceeded the maximum number of retries
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "Vault readiness check timed out after $MAX_RETRIES retries."
    exit 1
  fi

  echo "Vault is not ready yet, retrying..."
  RETRY_COUNT=$((RETRY_COUNT + 1))
  sleep $RETRY_INTERVAL
done
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

# Generate keys for Ansible (environment-agnostic)
generate_and_store_keypair "ansible" "${SSH_KEYS_DIR}/ansible"

# Generate keys for remote hosts (environment-specific)
generate_and_store_keypair "linux_ssh_keys_host" "${SSH_KEYS_DIR}/${ENVIRONMENT}/linux_ssh_keys_host"

# Bring the Vault server process to the foreground
wait $VAULT_PID
