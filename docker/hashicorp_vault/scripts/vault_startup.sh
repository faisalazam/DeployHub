#!/bin/sh

# Ensure ENVIRONMENT variable is set
if [ -z "$ENVIRONMENT" ]; then
  echo "Error: ENVIRONMENT variable is not set. Please set it before running the script."
  exit 1
fi

# Wait for Vault to be ready
echo "Waiting for Vault to be ready..."
until vault status > /dev/null 2>&1; do
  sleep 2
done
echo "Vault is ready."

generate_and_store_keypair() {
  MACHINE_NAME=$1
  KEYS_DIR="ssh_keys/${ENVIRONMENT}/${MACHINE_NAME}"

  # Check if keys already exist
  if ! vault kv get "${KEYS_DIR}" > /dev/null 2>&1; then
    echo "Generating keys for ${MACHINE_NAME} in environment ${ENVIRONMENT}..."
    ssh-keygen -t rsa -b 2048 -f "/tmp/${MACHINE_NAME}_id_rsa" -N ""
    vault kv put "${KEYS_DIR}" \
      id_rsa=@"/tmp/${MACHINE_NAME}_id_rsa" \
      id_rsa.pub=@"/tmp/${MACHINE_NAME}_id_rsa.pub"
    rm -f "/tmp/${MACHINE_NAME}_id_rsa" "/tmp/${MACHINE_NAME}_id_rsa.pub"
  else
    echo "Keys for ${MACHINE_NAME} already exist in Vault for environment ${ENVIRONMENT}."
  fi
}

# Generate keys for Ansible and remote hosts
generate_and_store_keypair "ansible"
generate_and_store_keypair "linux_ssh_keys_host"
