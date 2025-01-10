#!/bin/sh

. /vault/scripts/common.sh

SECRETS_PATH="secret"
ROOT_TOKEN_KEY="ROOT_TOKEN"

if [ "$SERVER_MODE" = "prod" ]; then
  log "Initializing Vault..."
  . /vault/scripts/initialize_vault.sh

  log "Unsealing Vault..."
  . /vault/scripts/unseal_vault.sh

  log "Logging in as root token..."
  login_with_token "${ROOT_TOKEN_KEY}" "/vault/secrets/auth/admin/root" "vault_token"

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
  save_key_value_to_file "$ROOT_TOKEN_KEY" "$VAULT_DEV_ROOT_TOKEN_ID" "/vault/secrets/auth/admin/root" "vault_token"

  log "Logging in as root token..."
  login_with_token "${ROOT_TOKEN_KEY}" "/vault/secrets/auth/admin/root" "vault_token"
fi

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
