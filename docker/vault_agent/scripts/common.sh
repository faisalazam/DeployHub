#!/bin/sh

# Timeout settings
RETRY_COUNT=0
MAX_RETRIES=30
RETRY_INTERVAL=1

log() {
  log_level="${2:-INFO}" # Default to INFO if no log level is provided
  echo "$(date --utc '+%Y-%m-%dT%H:%M:%S.%3NZ') [$log_level] $1"
}

check_vault_status() {
  # Wait for the Vault agent to be ready
  while ! vault status > /dev/null 2>&1 && [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    log "Waiting for Vault agent to be ready. Attempt #$((RETRY_COUNT + 1))..." "INFO"
    sleep $RETRY_INTERVAL
    RETRY_COUNT=$((RETRY_COUNT + 1))
  done

  # Check if Vault agent is ready after retries
  if ! vault status > /dev/null 2>&1; then
    log "Vault agent is not ready after $MAX_RETRIES attempts. Exiting..." "ERROR"
    exit 1
  fi

  log "Vault agent is ready."
}

login_with_token() {
  KEY_NAME=$1
  FILE_DIR=$2
  FILE_NAME=$3
  TOKEN_FILE="$FILE_DIR/$FILE_NAME"

  if [ ! -f "$TOKEN_FILE" ]; then
    log "Key file '$TOKEN_FILE' not found. Exiting..." "ERROR"
    exit 1
  fi

  if [ ! -s "$TOKEN_FILE" ]; then
    log "Key file '$TOKEN_FILE' is empty. Exiting..." "ERROR"
    exit 1
  fi

  LOGIN_TOKEN=$(cat "$TOKEN_FILE")
  if [ -z "$LOGIN_TOKEN" ]; then
    log "Token with $KEY_NAME is empty. Exiting..." "ERROR"
    exit 1
  fi

  log "Logging in with the $KEY_NAME token..."
  if ! vault login "$LOGIN_TOKEN" > /dev/null 2>&1; then
    log "Failed to log in with the $KEY_NAME token. Exiting..." "ERROR"
    exit 1
  fi
  log "Successfully logged in with the $KEY_NAME."
}
