#!/bin/sh

# Create required directories
mkdir -p "/vault/secrets/config"
mkdir -p "/vault/secrets/auth/agent/$SSH_MANAGER_ROLE_NAME"
mkdir -p "/vault/secrets/auth/ansible/ssh_keys/$ENVIRONMENT"

# Set ownership and permissions for security
chown -R vault:vault /vault/secrets
chmod -R 770 /vault/secrets

# Substitute variables in HCL using sed
sed -e "s|\${VAULT_ADDR}|$VAULT_ADDR|g" \
    -e "s|\${ENVIRONMENT}|$ENVIRONMENT|g" \
    -e "s|\${SSH_MANAGER_ROLE_NAME}|$SSH_MANAGER_ROLE_NAME|g" \
    /vault/config/vault_agent.hcl > /vault/secrets/config/vault_agent_resolved.hcl

# Start the Vault Agent
vault agent -config=/vault/secrets/config/vault_agent_resolved.hcl
