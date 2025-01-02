#!/bin/sh

. /opt/vault/common.sh

# Constants
KEY_SHARES=3
KEY_THRESHOLD=2
# Allow overriding KEYS_FILE via an environment variable
: "${KEYS_FILE:=/opt/vault/keys/keys.txt}"

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
  log "Initializing Vault..."
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
  log "Vault has been initialized. Keys saved to $KEYS_FILE."
else
  log "Vault initialization status is unknown!"
  exit 1
fi

# Unseal Vault if sealed
if echo "$VAULT_STATUS" | grep -qE "Sealed\s+true"; then
  log "Unsealing Vault..."

  # Read unseal keys from file
  if [ -f "$KEYS_FILE" ]; then
    # Unseal Vault with keys (only the first $KEY_SHARES unseal keys, excluding the root token)
    UNSEAL_KEYS=$(awk 'NR>1 {print $NF}' "$KEYS_FILE" | head -n "$KEY_SHARES")
    for KEY in $UNSEAL_KEYS; do
      if ! vault operator unseal "$KEY" > /dev/null 2>&1; then
        log "Error: Failed to unseal Vault with key: $KEY"
        exit 1
      fi
    done
    log "Vault has been unsealed."
  else
    log "Error: Unseal keys file not found. Cannot unseal Vault."
    exit 1
  fi
else
  log "Vault is already unsealed."
fi

# Wait for Vault readiness
log "Waiting for Vault to become ready..."
check_vault_status '"sealed":false'
log "Vault is unsealed and ready."
