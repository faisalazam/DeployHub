#!/bin/sh

# Timeout settings
RETRY_COUNT=0
MAX_RETRIES=10
RETRY_INTERVAL=1
KEYS_FILE="/opt/vault/keys/keys.txt"

# Wait for Vault to be ready
check_vault_status() {
  STATUS_TEXT=$1
  until printf 'GET /v1/sys/health HTTP/1.1\r\nHost: localhost\r\n\r\n' \
                | nc -w 5 127.0.0.1 8200 \
                | grep -E "${STATUS_TEXT}" > /dev/null 2>&1; do
    # Check if we've exceeded the maximum number of retries
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
      echo "Vault readiness check timed out after $MAX_RETRIES retries."
      exit 1
    fi

    echo "Vault is not ready yet, retrying..."
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep $RETRY_INTERVAL
  done
}

login_with_token() {
  LINE_NUMBER=$1
  if [ -f "$KEYS_FILE" ]; then
    LOGIN_TOKEN=$(sed -n "$LINE_NUMBER" "$KEYS_FILE" | awk '{print $NF}')
    echo "Logging in with THE required token..."
    vault login "$LOGIN_TOKEN"
  else
    echo "Login token file is missing, cannot login."
    exit 1
  fi
}
