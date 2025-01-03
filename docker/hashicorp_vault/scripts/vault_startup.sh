#!/bin/sh

. /opt/vault/common.sh

if [ -z "$ENVIRONMENT" ]; then
  log "ENVIRONMENT variable is not set. Please set it before running the script." "ERROR"
  exit 1
fi

log "Starting Vault setup..."
. /opt/vault/start_vault.sh

log "Configuring Vault Environment..."
sh /opt/vault/vault_configure.sh

log "Create Service Account/Token with Vault Policy..."
sh /opt/vault/create_svc_token_with_policy.sh

log "Generating and storing SSH keys..."
sh /opt/vault/generate_and_store_keypair.sh

wait "$VAULT_PID"
