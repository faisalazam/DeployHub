#!/bin/sh

# Path of ssh_keys inside the Hashicorp Vault
SSH_KEYS_DIR="secret/ssh_keys"

. /vault/scripts/common.sh

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

log "Logging in as ${SSH_MANAGER_ROLE_NAME} role..."
login_with_token "${SSH_MANAGER_ROLE_NAME}" "${VAULT_AGENT_ROLE_AUTH_DIR}" "vault_token"

generate_and_store_keypair "ansible" "${SSH_KEYS_DIR}/ansible"
generate_and_store_keypair "linux_explicit_ssh_keys_host" "${SSH_KEYS_DIR}/${ENVIRONMENT}/linux_explicit_ssh_keys_host"
