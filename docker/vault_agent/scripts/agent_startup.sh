#!/bin/sh

# Create required directories
mkdir -p "/vault/secrets/auth/agent/$SSH_MANAGER_ROLE_NAME"
mkdir -p "/vault/secrets/auth/ansible/ssh_keys/$ENVIRONMENT"

# Set ownership and permissions for security
chown -R vault:vault /vault/secrets
chmod -R 770 /vault/secrets

# Start the Vault Agent
vault agent -config=/vault/config/vault_agent.hcl
