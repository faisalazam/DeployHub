#!/bin/sh

. /vault/scripts/common.sh

# Create required directories
mkdir -p "/vault/secrets/config"
mkdir -p "/vault/secrets/auth/ssh_keys"
mkdir -p "/vault/secrets/auth/agent/$SSH_MANAGER_ROLE_NAME"

# Set ownership and permissions for security
chown -R vault:vault /vault/secrets
chmod -R 770 /vault/secrets

# Combine all .hcl files in the /vault/config directory
cat /vault/config/*.hcl > /vault/secrets/config/vault_agent_combined.hcl

# Substitute variables in HCL using sed
sed -e "s|\${VAULT_ADDR}|$VAULT_ADDR|g" \
    -e "s|\${ENVIRONMENT}|$ENVIRONMENT|g" \
    -e "s|\${SSH_MANAGER_ROLE_NAME}|$SSH_MANAGER_ROLE_NAME|g" \
    /vault/secrets/config/vault_agent_combined.hcl > /vault/secrets/config/vault_agent_resolved.hcl

# Start the Vault Agent
vault agent -config=/vault/secrets/config/vault_agent_resolved.hcl &
AGENT_PID=$!  # Capture the process ID of the Vault Agent

check_vault_status

log "Generating and storing SSH keys..."
. /vault/scripts/generate_and_store_keypair.sh

log "Fetching SSH keys..."
. /vault/scripts/fetch_ssh_keys.sh

wait "$AGENT_PID"
