#!/bin/sh

ROOT_TOKEN_KEY="ROOT_TOKEN"

. /vault/scripts/common.sh

# Check if 'vault' command is available
if ! command -v vault > /dev/null 2>&1; then
  log "'vault' command not found. Please ensure Vault CLI is installed." "ERROR"
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

  dir_name=$(dirname "$KEYS_FILE")
  if ! mkdir -p "$dir_name"; then
    log "Could not create $dir_name directory. Exiting..." "ERROR"
    exit 1
  fi

  # TODO: store these somewhere secure instead of the file in the container.
  # May be in the CI's credentials manger, AWS KMS etc.
  # Save unseal keys and root token to the keys file (sensitive data stored securely)
  if ! {
    echo "Unseal_Keys:"
    echo "$UNSEAL_KEYS" | nl -w2 -s": "
  } > "$KEYS_FILE" || [ ! -f "$KEYS_FILE" ] || [ ! -w "$KEYS_FILE" ]; then
    log "Failed to write unseal keys to $KEYS_FILE or file is not writable. Exiting..." "ERROR"
    exit 1
  fi

  # Secure the file (e.g., read/write only for the owner)
  chmod 700 "$AUTH_DIR"    # Restrict access to the keys directory
  chmod 600 "$KEYS_FILE"   # Restrict access to the keys file

  # Change the owner to the vault user for both the directory and the keys file
  if ! chown -R vault:vault "$AUTH_DIR" "$KEYS_FILE"; then
    log "Failed to change ownership to 'vault' for $AUTH_DIR and $KEYS_FILE. Exiting..." "ERROR"
    exit 1
  fi

  # Extract and save root token
  ROOT_TOKEN=$(echo "$INIT_OUTPUT" | grep 'Initial Root Token' | awk '{print $NF}')
  save_key_value_to_file "$ROOT_TOKEN_KEY" "$ROOT_TOKEN" "/vault/secrets/auth/admin/root" "vault_token"

  log "Vault has been initialized. Keys saved to $KEYS_FILE."
else
  log "Vault initialization status is unknown!"
  exit 1
fi
