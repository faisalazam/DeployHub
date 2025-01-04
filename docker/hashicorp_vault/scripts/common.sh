#!/bin/sh

# Timeout settings
RETRY_COUNT=0
MAX_RETRIES=10
RETRY_INTERVAL=1
# shellcheck disable=SC2034
KEY_SHARES=3
# shellcheck disable=SC2034
KEY_THRESHOLD=2
KEYS_DIR="/vault/keys"
# shellcheck disable=SC2034
KEYS_FILE="$KEYS_DIR/KEYS"
: "${KEYS_DIR:=/vault/keys}"

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
  KEY_NAME=$1
  TOKEN_FILE="$KEYS_DIR/$KEY_NAME"

  if [ ! -f "$TOKEN_FILE" ]; then
    log "Key file '$TOKEN_FILE' not found. Exiting..." "ERROR"
    exit 1
  fi

  if [ ! -s "$TOKEN_FILE" ]; then
    log "Key file '$TOKEN_FILE' is empty. Exiting..." "ERROR"
    exit 1
  fi

  LOGIN_TOKEN=$(cat "$KEYS_DIR/$KEY_NAME")
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

save_key_value_to_file() {
  KEY="$1"
  VALUE="$2"

  if [ -z "$VALUE" ]; then
    log "Failed to create '${KEY}' value. Exiting..." "ERROR"
    exit 1
  fi

  # Mask the value (show last 4 characters and mask the rest)
  MASKED_VALUE=$(echo "$VALUE" | sed 's/.*\(....\)$/****\1/')
  log "${KEY} created: $MASKED_VALUE"

  log "Saving ${KEY}..."

  if ! echo "$VALUE" > "$KEYS_DIR/$KEY"; then
    log "Failed to save ${KEY} in $KEYS_DIR/$KEY. Exiting..." "ERROR"
    exit 1
  fi
  chmod 600 "$KEYS_DIR/$KEY"   # Restrict access to the key file

  log "${KEY} has been saved in $KEYS_DIR/$KEY."
}