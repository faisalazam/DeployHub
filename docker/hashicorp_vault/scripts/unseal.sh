#!/bin/sh

KEYS_FILE="/opt/vault/keys/keys.txt"

# Check Vault initialization status
VAULT_STATUS=$(vault status)
if echo "$VAULT_STATUS" | grep -qE "Initialized\s+true"; then
  echo "Vault is already initialized!"
elif echo "$VAULT_STATUS" | grep -qE "Initialized\s+false"; then
  echo "Initializing Vault..."
  INIT_OUTPUT=$(vault operator init -key-shares=3 -key-threshold=2)

  # Extract unseal keys and root token from the initialization output
  UNSEAL_KEY_1=$(echo "$INIT_OUTPUT" | grep 'Unseal Key 1' | awk '{print $NF}')
  UNSEAL_KEY_2=$(echo "$INIT_OUTPUT" | grep 'Unseal Key 2' | awk '{print $NF}')
  UNSEAL_KEY_3=$(echo "$INIT_OUTPUT" | grep 'Unseal Key 3' | awk '{print $NF}')
  ROOT_TOKEN=$(echo "$INIT_OUTPUT" | grep 'Initial Root Token' | awk '{print $NF}')

  # Save the unseal keys and root token to a file for backup
  {
    echo "Unseal Keys:"
    echo "Key 1: $UNSEAL_KEY_1"
    echo "Key 2: $UNSEAL_KEY_2"
    echo "Key 3: $UNSEAL_KEY_3"
    echo "Root Token: $ROOT_TOKEN"
  } > $KEYS_FILE
  echo "Vault has been initialized."
else
  echo "Vault initialization status is unknown!"
  exit 1
fi

# Unseal Vault (only if it's not already unsealed)
if echo "$VAULT_STATUS" | grep -qE "Sealed\s+true"; then
  echo "Unsealing Vault..."

  # Read unseal keys from file
  if [ -f "$KEYS_FILE" ]; then
    UNSEAL_KEY_1=$(sed -n '2p' "$KEYS_FILE" | awk '{print $NF}')
    UNSEAL_KEY_2=$(sed -n '3p' "$KEYS_FILE" | awk '{print $NF}')
    UNSEAL_KEY_3=$(sed -n '4p' "$KEYS_FILE" | awk '{print $NF}')

    # Unseal with keys
    vault operator unseal "$UNSEAL_KEY_1"
    vault operator unseal "$UNSEAL_KEY_2"
    vault operator unseal "$UNSEAL_KEY_3"
  else
    echo "Unseal keys file is missing, cannot unseal Vault."
    exit 1
  fi
else
  echo "Vault is already unsealed."
fi

# Login as root token
if [ -f "$KEYS_FILE" ]; then
  ROOT_TOKEN=$(sed -n '5p' "$KEYS_FILE" | awk '{print $NF}')
  echo "Logging in with root token..."
  vault login "$ROOT_TOKEN"
else
  echo "Root token file is missing, cannot login."
  exit 1
fi

# Wait for Vault to become ready
echo "Waiting for Vault to become ready..."
. /opt/vault/common.sh
check_vault_status '"sealed":false'
echo "Vault is unsealed and ready."
