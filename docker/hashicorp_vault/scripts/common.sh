#!/bin/sh

# Timeout settings
RETRY_COUNT=0
MAX_RETRIES=10
RETRY_INTERVAL=1
# shellcheck disable=SC2034
KEY_SHARES=3
# shellcheck disable=SC2034
KEY_THRESHOLD=2
KEYS_FILE="/opt/vault/keys/keys.txt"
: "${KEYS_FILE:=/opt/vault/keys/keys.txt}"

log() {
  log_level="${2:-INFO}" # Default to INFO if no log level is provided
  echo "$(date --utc '+%Y-%m-%dT%H:%M:%S.%3NZ') [$log_level] $1"
}

# Wait for Vault to be ready
check_vault_status() {
  STATUS_TEXT=$1
  if ! command -v nc > /dev/null 2>&1; then
    log "'nc' (Netcat) command not found. Please install it to proceed." "ERROR"
    exit 1
  fi
  until printf 'GET /v1/sys/health HTTP/1.1\r\nHost: localhost\r\n\r\n' \
                | nc -w 5 127.0.0.1 8200 \
                | grep -E "${STATUS_TEXT}" > /dev/null 2>&1; do
    # Check if we've exceeded the maximum number of retries
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
      log "Vault readiness check timed out after $MAX_RETRIES retries."
      exit 1
    fi

    log "Vault is not ready yet, retrying... (${RETRY_COUNT}/${MAX_RETRIES})"
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep $RETRY_INTERVAL
  done
  log "Vault is ready."
}

login_with_token() {
  LINE_NUMBER=$1

  if [ ! -f "$KEYS_FILE" ]; then
    log "Key file '$KEYS_FILE' not found. Exiting..." "ERROR"
    exit 1
  fi

  if [ ! -s "$KEYS_FILE" ]; then
    log "Key file '$KEYS_FILE' is empty. Exiting..." "ERROR"
    exit 1
  fi

  LOGIN_TOKEN=$(sed -n "$LINE_NUMBER" "$KEYS_FILE" | awk '{print $NF}')
  if [ -z "$LOGIN_TOKEN" ]; then
    log "Token at line $LINE_NUMBER is empty. Exiting..." "ERROR"
    exit 1
  fi

  log "Logging in with the required token..."
  if ! vault login "$LOGIN_TOKEN" > /dev/null 2>&1; then
    log "Failed to log in with the token. Exiting..." "ERROR"
    exit 1
  fi
  log "Successfully logged in with the token."
}
