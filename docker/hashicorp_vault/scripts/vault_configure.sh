#!/bin/sh

. /opt/vault/common.sh

ROOT_TOKEN_LINE=5
TOTAL_LINES_IN_FILE=6
SECRETS_PATH="secret"

if [ "$SERVER_MODE" = "prod" ]; then
  log "Initializing Vault..."
  . /opt/vault/initialize_vault.sh

  log "Unsealing Vault..."
  . /opt/vault/unseal_vault.sh

  log "Logging in as root token..."
  login_with_token "${ROOT_TOKEN_LINE}p"

  log "Enabling AppRole authentication method..."
  if vault auth list | grep -q "approle"; then
    log "AppRole auth method is already enabled. Skipping..."
  else
    if ! vault auth enable approle; then
      log "Failed to enable AppRole auth method. Exiting..." "ERROR"
      exit 1
    fi
    log "AppRole auth method has been enabled."
  fi

  log "Enabling Secrets Engine at path=${SECRETS_PATH}..."
  if vault read "sys/mounts/${SECRETS_PATH}" > /dev/null 2>&1; then
    log "Secrets engine at path=${SECRETS_PATH} is already enabled. Skipping..."
  else
    if ! vault secrets enable -path="${SECRETS_PATH}" kv-v2; then
      log "Failed to enable secrets engine at path=${SECRETS_PATH}. Exiting..." "ERROR"
      exit 1
    fi
    log "Secrets engine at path=${SECRETS_PATH} has been enabled."
  fi
else
  touch "$KEYS_FILE"
  while [ "$(wc -l < "$KEYS_FILE")" -lt $TOTAL_LINES_IN_FILE ]; do
    echo "" >> "$KEYS_FILE"
  done
  sed -i "${ROOT_TOKEN_LINE}c\Non-root token: $VAULT_DEV_ROOT_TOKEN_ID" "$KEYS_FILE"

  log "Logging in as root token..."
  login_with_token "${ROOT_TOKEN_LINE}p"
fi