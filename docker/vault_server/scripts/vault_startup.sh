#!/bin/sh

. /vault/scripts/common.sh

if [ -z "$ENVIRONMENT" ]; then
  log "ENVIRONMENT variable is not set. Please set it before running the script." "ERROR"
  exit 1
fi

log "Starting Vault setup..."
. /vault/scripts/start_vault.sh

log "Configuring Vault Environment..."
. /vault/scripts/vault_configure.sh

log "Create Service Account/Token with Vault Policy..."
. /vault/scripts/create_svc_token_with_policy.sh

wait "$VAULT_PID"
