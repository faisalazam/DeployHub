#!/bin/sh

. /vault/scripts/common.sh

terminate_vault() {
  if [ -n "$VAULT_PID" ]; then
    log "Terminating Vault server..."
    kill $VAULT_PID
    wait $VAULT_PID 2>/dev/null
    log "Vault server terminated."
  else
    log "Vault server was not running."
  fi
}

trap terminate_vault INT TERM EXIT

# Start Vault server in the background
log "Starting Vault server..."
if [ "$SERVER_MODE" = "prod" ]; then
  export VAULT_EXTERNAL_PORT=8200
  sed "s|\${VAULT_EXTERNAL_PORT}|$VAULT_EXTERNAL_PORT|g" /vault/config/vault_config.hcl > /vault/config/vault_config_substituted.hcl
  vault server -config=/vault/config/vault_config_substituted.hcl &
else
  export VAULT_EXTERNAL_PORT=8300
  sed "s|\${VAULT_EXTERNAL_PORT}|$VAULT_EXTERNAL_PORT|g" /vault/config/vault_config.hcl > /vault/config/vault_config_substituted.hcl
  vault server -dev -config=/vault/config/vault_config_substituted.hcl &
fi
VAULT_PID=$!  # Capture the process ID of the Vault server

log "Waiting for Vault to be ready..."
check_vault_status "200 OK|initialized"
