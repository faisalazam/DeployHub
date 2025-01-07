#!/bin/sh

. /vault/scripts/common.sh

SECRETS_DIR="/vault/secrets"

if [ -e "$SECRETS_DIR" ]; then
  log "Directory exists: $SECRETS_DIR.  Cleaning contents..."
  rm -rf "${SECRETS_DIR:?}/"* || {
    log "Failed to delete the contents of $SECRETS_DIR. Exiting." "ERROR"
    exit 1
  }
  log "Successfully cleaned up $SECRETS_DIR."
else
  log "Directory does not exist: $SECRETS_DIR. Nothing to clean up."
fi

# Create required directories
mkdir -p "$SECRETS_DIR/config"
mkdir -p "$SECRETS_DIR/auth/ssh_keys"
mkdir -p "$SECRETS_DIR/agent/auth/$SSH_MANAGER_ROLE_NAME"

# Set ownership and permissions for security
chown -R vault:vault "$SECRETS_DIR"
chmod -R 770 "$SECRETS_DIR"

# Combine all .hcl files in the /vault/config directory
cat /vault/config/*.hcl > "$SECRETS_DIR/config/vault_agent_combined.hcl"

# Substitute variables in HCL using sed
sed -e "s|\${VAULT_ADDR}|$VAULT_ADDR|g" \
    -e "s|\${ENVIRONMENT}|$ENVIRONMENT|g" \
    -e "s|\${SSH_MANAGER_ROLE_NAME}|$SSH_MANAGER_ROLE_NAME|g" \
    "$SECRETS_DIR/config/vault_agent_combined.hcl" > "$SECRETS_DIR/config/vault_agent_resolved.hcl"

# Start the Vault Agent
vault agent -config="$SECRETS_DIR/config/vault_agent_resolved.hcl" &
AGENT_PID=$!  # Capture the process ID of the Vault Agent

check_vault_status

log "Generating and storing SSH keys..."
. /vault/scripts/generate_and_store_keypair.sh

log "Fetching SSH keys..."
. /vault/scripts/fetch_ssh_keys.sh

wait "$AGENT_PID"
