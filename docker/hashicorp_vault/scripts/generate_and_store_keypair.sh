#!/bin/sh

NON_ROOT_TOKEN_LINE=6
SECRETS_PATH="secret"
SSH_KEYS_DIR="${SECRETS_PATH}/ssh_keys"

. /opt/vault/common.sh

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

log "Logging in as non-root token..."
login_with_token "${NON_ROOT_TOKEN_LINE}p"

generate_and_store_keypair "ansible" "${SSH_KEYS_DIR}/ansible"
generate_and_store_keypair "linux_ssh_keys_host" "${SSH_KEYS_DIR}/${ENVIRONMENT}/linux_ssh_keys_host"
