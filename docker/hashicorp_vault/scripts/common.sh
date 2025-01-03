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
  echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Wait for Vault to be ready
check_vault_status() {
  STATUS_TEXT=$1
  if ! command -v nc > /dev/null 2>&1; then
    log "Error: 'nc' (Netcat) command not found. Please install it to proceed."
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
    log "Error: Key file '$KEYS_FILE' not found. Exiting..."
    exit 1
  fi

  if [ ! -s "$KEYS_FILE" ]; then
    log "Error: Key file '$KEYS_FILE' is empty. Exiting..."
    exit 1
  fi

  LOGIN_TOKEN=$(sed -n "$LINE_NUMBER" "$KEYS_FILE" | awk '{print $NF}')
  if [ -z "$LOGIN_TOKEN" ]; then
    log "Error: Token at line $LINE_NUMBER is empty. Exiting..."
    exit 1
  fi

  log "Logging in with the required token..."
  if ! vault login "$LOGIN_TOKEN" > /dev/null 2>&1; then
    log "Error: Failed to log in with the token. Exiting..."
    exit 1
  fi
  log "Successfully logged in with the token."
}
