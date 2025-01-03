#!/bin/sh

. /opt/vault/common.sh

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

if [ -z "$ENVIRONMENT" ]; then
  log "ENVIRONMENT variable is not set. Please set it before running the script." "ERROR"
  exit 1
fi

log "Waiting for Vault to be ready..."
check_vault_status "200 OK|initialized"
log "Vault is ready."

log "Configuring Vault Environment..."
sh /opt/vault/vault_configure.sh

log "Create Service Account/Token with Vault Policy..."
sh /opt/vault/create_svc_token_with_policy.sh

log "Generating and storing SSH keys..."
sh /opt/vault/generate_and_store_keypair.sh

wait "$VAULT_PID"
