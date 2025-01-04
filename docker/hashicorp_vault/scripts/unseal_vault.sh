#!/bin/sh

. /vault/scripts/common.sh

# Check if 'vault' command is available
if ! command -v vault > /dev/null 2>&1; then
  log "'vault' command not found. Please ensure Vault CLI is installed." "ERROR"
  exit 1
fi

# Unseal Vault if sealed
VAULT_STATUS=$(vault status 2>&1)
if echo "$VAULT_STATUS" | grep -qE "Sealed\s+true"; then
  log "Unsealing Vault..."

  # Read unseal keys from file
  if [ -f "$KEYS_FILE" ]; then
    # Unseal Vault with keys (only the first $KEY_SHARES unseal keys, excluding the root token)
    UNSEAL_KEYS=$(awk '/^[[:space:]]*[0-9]+:/ {print $2}' "$KEYS_FILE" | head -n "$KEY_SHARES")
    if [ -z "$UNSEAL_KEYS" ]; then
      log "No unseal keys were retrieved. Check the $KEYS_FILE or $KEY_SHARES." "ERROR"
      exit 1
    fi

    for KEY in $UNSEAL_KEYS; do
      if ! vault operator unseal "$KEY" > /dev/null 2>&1; then
        log "Failed to unseal Vault with key: $KEY" "ERROR"
        exit 1
      fi
    done
    log "Vault has been unsealed."
  else
    log "Unseal keys file not found. Cannot unseal Vault." "ERROR"
    exit 1
  fi
else
  log "Vault is already unsealed."
fi

# Wait for Vault readiness
log "Waiting for Vault to become ready..."
check_vault_status '"sealed":false'
log "Vault is unsealed and ready."
