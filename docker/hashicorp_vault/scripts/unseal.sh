#!/bin/sh

KEYS_FILE="/opt/vault/keys/keys.txt"

if vault status | grep -qE "Initialized\s+true"; then
  echo "Vault is already initialized!"
elif vault status | grep -qE "Initialized\s+false"; then
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
else
  echo "Vault initialization status is unknown!"
fi

# Unseal Vault (only if it's not already unsealed)
if vault status | grep -qE "Sealed\s+true"; then
  echo "Unsealing Vault..."
  UNSEAL_KEY_1=$(sed -n '2p' "$KEYS_FILE" | awk '{print $NF}')
  UNSEAL_KEY_2=$(sed -n '3p' "$KEYS_FILE" | awk '{print $NF}')
  UNSEAL_KEY_3=$(sed -n '4p' "$KEYS_FILE" | awk '{print $NF}')

  vault operator unseal "$UNSEAL_KEY_1"
  vault operator unseal "$UNSEAL_KEY_2"
  vault operator unseal "$UNSEAL_KEY_3"
else
  echo "Vault is already unsealed."
fi

echo "Logging in as root"
ROOT_TOKEN=$(sed -n '5p' "$KEYS_FILE" | awk '{print $NF}')
vault login "$ROOT_TOKEN"

# Wait for Vault to become ready
echo "Waiting for Vault to become ready..."
until vault status | grep -qE "Sealed\s+false"; do
  echo "Vault is still sealed, retrying..."
  sleep 5
done

echo "Vault is unsealed and ready."
