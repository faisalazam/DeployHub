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

substitute_variables_in_file() {
  template_file="$1"

  # Loop through environment variables and substitute them in the target or template file
  env | while IFS='=' read -r var value; do
    # Only process variables that are not empty
    if [ -n "$value" ]; then
      sed -i "s|\${$var}|$value|g" "$template_file"
    fi
  done
}

trap terminate_vault INT TERM EXIT

# shellcheck disable=SC2153
SERVER_CONFIG_DIR="$SERVER_DIR/config"
SERVER_CONFIG_FILE="$SERVER_CONFIG_DIR/vault_server.hcl"
mkdir -p "$SERVER_CONFIG_DIR"
cp "/vault/config/vault_server.hcl" "$SERVER_CONFIG_FILE"

log "Starting Vault server in the background..."
if [ "$SERVER_MODE" = "prod" ]; then
  export VAULT_EXTERNAL_PORT=8200
  substitute_variables_in_file "$SERVER_CONFIG_FILE"
  vault server -config="$SERVER_CONFIG_FILE" &
else
  export VAULT_EXTERNAL_PORT=8300
  substitute_variables_in_file "$SERVER_CONFIG_FILE"
  vault server -dev -config="$SERVER_CONFIG_FILE" &
fi

VAULT_PID=$!  # Capture the process ID of the Vault server

log "Waiting for Vault to be ready..."
check_vault_status "Initialized"
