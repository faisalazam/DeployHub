#!/bin/sh

. /vault/scripts/common.sh

# Fetch the list of machines from Vault
MACHINES=$(vault kv list "secret/ssh_keys/${ENVIRONMENT}" | tail -n +3)  # List keys and ignore the first two lines (headers)

if [ -z "$MACHINES" ]; then
  log "No machines found under secret/ssh_keys/${ENVIRONMENT}. Exiting..."
  exit 1
fi

# Iterate over each machine and create templates dynamically
for MACHINE in $MACHINES; do
  MACHINE_PATH="secret/data/ssh_keys/${ENVIRONMENT}/${MACHINE}"

  # Fetch id_rsa
  log "Fetching id_rsa for $MACHINE..."
  vault kv get -field=id_rsa "$MACHINE_PATH" > "/vault/secrets/auth/ssh_keys/${ENVIRONMENT}/${MACHINE}/id_rsa"

  # Fetch id_rsa.pub
  log "Fetching id_rsa.pub for $MACHINE..."
  vault kv get -field=id_rsa.pub "$MACHINE_PATH" > "/vault/secrets/auth/ssh_keys/${ENVIRONMENT}/${MACHINE}/id_rsa.pub"

  # Set permissions for the keys
  chmod 600 "/vault/secrets/auth/ssh_keys/${ENVIRONMENT}/${MACHINE}/id_rsa"
  chmod 644 "/vault/secrets/auth/ssh_keys/${ENVIRONMENT}/${MACHINE}/id_rsa.pub"

  log "SSH keys fetched and stored for $MACHINE."
done