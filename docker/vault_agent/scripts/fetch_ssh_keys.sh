#!/bin/sh

. /vault/scripts/common.sh

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

# Iterate over each machine and create templates dynamically
for MACHINE in $MACHINES; do
  MACHINE_PATH="secret/ssh_keys/${ENVIRONMENT}/${MACHINE}"
  SSH_KEYS_DIR="/vault/secrets/auth/ssh_keys/${ENVIRONMENT}/${MACHINE}"

  log "Processing keys for $MACHINE..."

  # Create directory for the machine's SSH keys
  if ! mkdir -p "$SSH_KEYS_DIR"; then
    log "Failed to create directory $SSH_KEYS_DIR. Skipping..." "ERROR"
    exit 1
  fi

  # Set directory permissions
  if ! chmod 700 "$SSH_KEYS_DIR"; then
    log "Failed to set permissions for directory $SSH_KEYS_DIR. Skipping..." "ERROR"
    rmdir "$SSH_KEYS_DIR" 2>/dev/null
    exit 1
  fi

  # Fetch id_rsa
  log "Fetching id_rsa for $MACHINE..."
  if ! vault kv get -field=id_rsa "$MACHINE_PATH" > "$SSH_KEYS_DIR/id_rsa"; then
    log "Failed to fetch id_rsa for $MACHINE. Exiting..." "ERROR"
    rm -f "$SSH_KEYS_DIR/id_rsa"
    rmdir "$SSH_KEYS_DIR" 2>/dev/null
    exit 1
  fi

  # Fetch id_rsa.pub
  log "Fetching id_rsa.pub for $MACHINE..."
  if ! vault kv get -field=id_rsa.pub "$MACHINE_PATH" > "$SSH_KEYS_DIR/id_rsa.pub"; then
    log "Failed to fetch id_rsa.pub for $MACHINE. Cleaning up..." "ERROR"
    rm -f "$SSH_KEYS_DIR/id_rsa" "$SSH_KEYS_DIR/id_rsa.pub"
    rmdir "$SSH_KEYS_DIR" 2>/dev/null
    exit 1
  fi

  # Set permissions for private key
  if ! chmod 600 "$SSH_KEYS_DIR/id_rsa"; then
    log "Failed to set permissions for id_rsa of $MACHINE. Cleaning up..." "ERROR"
    rm -f "$SSH_KEYS_DIR/id_rsa" "$SSH_KEYS_DIR/id_rsa.pub"
    rmdir "$SSH_KEYS_DIR" 2>/dev/null
    exit 1
  fi

  # Set permissions for public key
  if ! chmod 644 "$SSH_KEYS_DIR/id_rsa.pub"; then
    log "Failed to set permissions for id_rsa.pub of $MACHINE. Cleaning up..." "ERROR"
    rm -f "$SSH_KEYS_DIR/id_rsa" "$SSH_KEYS_DIR/id_rsa.pub"
    rmdir "$SSH_KEYS_DIR" 2>/dev/null
    exit 1
  fi

  log "SSH keys successfully fetched and stored for $MACHINE."
done

log "All keys for ${ENVIRONMENT} environment fetched successfully."
