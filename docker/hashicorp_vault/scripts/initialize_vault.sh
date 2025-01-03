#!/bin/sh

. /opt/vault/common.sh

# Check if 'vault' command is available
if ! command -v vault > /dev/null 2>&1; then
  log "Error: 'vault' command not found. Please ensure Vault CLI is installed."
  exit 1
fi

# Check Vault initialization status
VAULT_STATUS=$(vault status 2>&1)
if echo "$VAULT_STATUS" | grep -qE "Initialized\s+true"; then
  log "Vault is already initialized."
elif echo "$VAULT_STATUS" | grep -qE "Initialized\s+false"; then
  log "Running vault operator init..."
  INIT_OUTPUT=$(vault operator init -key-shares="$KEY_SHARES" -key-threshold="$KEY_THRESHOLD" 2>&1)

  # Extract unseal keys from lines 2, 3, ..., KEY_SHARES+1
  UNSEAL_KEYS=$(echo "$INIT_OUTPUT" | grep 'Unseal Key' | awk '{print $NF}' | head -n "$KEY_SHARES")

  # Extract root token
  ROOT_TOKEN=$(echo "$INIT_OUTPUT" | grep 'Initial Root Token' | awk '{print $NF}')

  # Save unseal keys and root token to the keys file (sensitive data stored securely)
  {
    echo "Unseal Keys:"
    echo "$UNSEAL_KEYS" | nl -w2 -s": "
    echo "Root Token: $ROOT_TOKEN"
    echo "Non-root token:" # Placeholder for Non-root token
  } > "$KEYS_FILE"

  # Secure the file (e.g., read/write only for the owner)
  chmod 600 "$KEYS_FILE"

  log "Vault has been initialized. Keys saved to $KEYS_FILE."
else
  log "Vault initialization status is unknown!"
  exit 1
fi
