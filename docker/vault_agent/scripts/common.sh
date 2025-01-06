#!/bin/sh

log() {
  log_level="${2:-INFO}" # Default to INFO if no log level is provided
  echo "$(date --utc '+%Y-%m-%dT%H:%M:%S.%3NZ') [$log_level] $1"
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
