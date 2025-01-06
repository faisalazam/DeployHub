#!/bin/sh

. /vault/scripts/common.sh

setup_ssh_keys_dir() {
  SSH_KEYS_DIR=$1
  if ! mkdir -p "$SSH_KEYS_DIR"; then
    log "Failed to create directory $SSH_KEYS_DIR. Skipping..." "ERROR"
    exit 1
  fi

  if ! chmod 700 "$SSH_KEYS_DIR"; then
    log "Failed to set permissions for directory $SSH_KEYS_DIR. Skipping..." "ERROR"
    rmdir "$SSH_KEYS_DIR" 2>/dev/null
    exit 1
  fi
}

fetch_ssh_keys() {
  SSH_PATH=$1
  SSH_KEYS_DIR=$2

  # Fetch id_rsa
  log "Fetching id_rsa from $SSH_PATH..."
  if ! vault kv get -field=id_rsa "$SSH_PATH" > "$SSH_KEYS_DIR/id_rsa"; then
    log "Failed to fetch id_rsa from $SSH_PATH. Exiting..." "ERROR"
    rm -f "$SSH_KEYS_DIR/id_rsa"
    rmdir "$SSH_KEYS_DIR" 2>/dev/null
    exit 1
  fi

  # Fetch id_rsa.pub
  log "Fetching id_rsa.pub from $SSH_PATH..."
  if ! vault kv get -field=id_rsa.pub "$SSH_PATH" > "$SSH_KEYS_DIR/id_rsa.pub"; then
    log "Failed to fetch id_rsa.pub from $SSH_PATH. Exiting..." "ERROR"
    rm -f "$SSH_KEYS_DIR/id_rsa" "$SSH_KEYS_DIR/id_rsa.pub"
    rmdir "$SSH_KEYS_DIR" 2>/dev/null
    exit 1
  fi

  # Set permissions for private key
  if ! chmod 600 "$SSH_KEYS_DIR/id_rsa"; then
    log "Failed to set permissions for id_rsa. Exiting..." "ERROR"
    rm -f "$SSH_KEYS_DIR/id_rsa" "$SSH_KEYS_DIR/id_rsa.pub"
    rmdir "$SSH_KEYS_DIR" 2>/dev/null
    exit 1
  fi

  # Set permissions for public key
  if ! chmod 644 "$SSH_KEYS_DIR/id_rsa.pub"; then
    log "Failed to set permissions for id_rsa.pub. Exiting..." "ERROR"
    rm -f "$SSH_KEYS_DIR/id_rsa" "$SSH_KEYS_DIR/id_rsa.pub"
    rmdir "$SSH_KEYS_DIR" 2>/dev/null
    exit 1
  fi
}

# Define ansible SSH keys path and directory
ANSIBLE_PATH="secret/ssh_keys/ansible"
ANSIBLE_SSH_KEYS_DIR="/vault/secrets/auth/ssh_keys/ansible"

log "Fetching ansible SSH keys for ansible..."
setup_ssh_keys_dir "$ANSIBLE_SSH_KEYS_DIR"
fetch_ssh_keys "$ANSIBLE_PATH" "$ANSIBLE_SSH_KEYS_DIR"
log "Ansible SSH keys successfully fetched and stored."

# Fetch the list of machines from Vault
log "Fetching list of machines from Vault..."
if ! MACHINES=$(vault kv list "secret/ssh_keys/${ENVIRONMENT}" | tail -n +3); then
  log "Failed to fetch machine list from Vault. Exiting..." "ERROR"
  exit 1
fi

if [ -z "$MACHINES" ]; then
  log "No machines found under secret/ssh_keys/${ENVIRONMENT}. Exiting..."
  exit 1
fi

for MACHINE in $MACHINES; do
  MACHINE_PATH="secret/ssh_keys/${ENVIRONMENT}/${MACHINE}"
  SSH_KEYS_DIR="/vault/secrets/auth/ssh_keys/${ENVIRONMENT}/${MACHINE}"

  log "Processing keys for $MACHINE..."
  setup_ssh_keys_dir "$SSH_KEYS_DIR"
  fetch_ssh_keys "$MACHINE_PATH" "$SSH_KEYS_DIR"
  log "SSH keys successfully fetched and stored for $MACHINE."
done

log "All keys for ${ENVIRONMENT} environment fetched successfully."
