#!/bin/sh

. /vault/scripts/common.sh

SECRETS_DIR="/vault/secrets"
AGENT_DIR="$SECRETS_DIR/agent"
AGENT_CONFIG_DIR="$AGENT_DIR/config"

clean_directory() {
  dir="$1"
  if [ -e "$dir" ]; then
    log "Directory exists: $dir. Cleaning contents..."
    rm -rf "${dir:?}/"* || {
      log "Failed to delete the contents of $dir. Exiting." "ERROR"
      exit 1
    }
    log "Successfully cleaned up $dir."
  else
    log "Directory does not exist: $dir. Nothing to clean up."
  fi
}

clean_directory "$AGENT_DIR"

# Create required directories
mkdir -p "$AGENT_CONFIG_DIR"
mkdir -p "$AGENT_DIR/ssh_keys"
mkdir -p "$AGENT_DIR/auth/$SSH_MANAGER_ROLE_NAME"

# Set ownership and permissions for security
chown -R vault:vault "$AGENT_DIR"
chmod -R 770 "$AGENT_DIR"

# Combine all .hcl files in the /vault/config directory
cat /vault/config/*.hcl > "$AGENT_CONFIG_DIR/vault_agent_combined.hcl"

# Substitute variables in HCL using sed
sed -e "s|\${VAULT_ADDR}|$VAULT_ADDR|g" \
    -e "s|\${ENVIRONMENT}|$ENVIRONMENT|g" \
    -e "s|\${SSH_MANAGER_ROLE_NAME}|$SSH_MANAGER_ROLE_NAME|g" \
    "$AGENT_CONFIG_DIR/vault_agent_combined.hcl" > "$AGENT_CONFIG_DIR/vault_agent.hcl"

rm -f "$AGENT_CONFIG_DIR/vault_agent_combined.hcl"

# Start the Vault Agent
vault agent -config="$AGENT_CONFIG_DIR/vault_agent.hcl" &
AGENT_PID=$!  # Capture the process ID of the Vault Agent

check_vault_status

log "Generating and storing SSH keys..."
. /vault/scripts/generate_and_store_keypair.sh

log "Fetching SSH keys..."
. /vault/scripts/fetch_ssh_keys.sh

wait "$AGENT_PID"
