#!/bin/sh

TOKEN_TTL="1h"
TOKEN_MAX_TTL="24h"
NON_ROOT_TOKEN_KEY="NON_ROOT_TOKEN"
SSH_MANAGER_ROLE_NAME="ssh_manager_role"
SSH_KEY_POLICY_NAME="ssh_key_policy"
SSH_KEY_POLICY_PATH="/vault/policies/ssh_key_policy.hcl"

. /vault/scripts/common.sh

apply_vault_policy() {
  log "Applying Vault policy..."
  if vault policy read ${SSH_KEY_POLICY_NAME} > /dev/null 2>&1; then
    log "Vault policy '${SSH_KEY_POLICY_NAME}' already exists. Skipping policy application..."
  else
    if ! vault policy write ${SSH_KEY_POLICY_NAME} ${SSH_KEY_POLICY_PATH}; then
      log "Failed to apply Vault policy '${SSH_KEY_POLICY_NAME}'. Exiting..." "ERROR"
      exit 1
    else
      log "Vault policy '${SSH_KEY_POLICY_NAME}' applied successfully."
    fi
  fi
}

create_approle() {
  log "Checking if AppRole ${SSH_MANAGER_ROLE_NAME} already exists..."
  if vault read -format=json auth/approle/role/${SSH_MANAGER_ROLE_NAME} > /dev/null 2>&1; then
    log "AppRole ${SSH_MANAGER_ROLE_NAME} already exists. Skipping creation."
  else
  log "Creating AppRole ${SSH_MANAGER_ROLE_NAME} with token_ttl=${TOKEN_TTL} and token_max_ttl=${TOKEN_MAX_TTL}..."
    if ! vault write auth/approle/role/${SSH_MANAGER_ROLE_NAME} \
                     policies="${SSH_KEY_POLICY_NAME}" \
                     token_ttl="${TOKEN_TTL}" \
                     token_max_ttl="${TOKEN_MAX_TTL}"; then
    log "Failed to create AppRole ${SSH_MANAGER_ROLE_NAME} with token_ttl=${TOKEN_TTL} and token_max_ttl=${TOKEN_MAX_TTL}. Exiting..." "ERROR"
      exit 1
    fi
  log "AppRole ${SSH_MANAGER_ROLE_NAME} has been created."
  fi
}

update_keys_file() {
  MASKED_NON_ROOT_TOKEN=$(echo "$NON_ROOT_TOKEN" | sed 's/^\(....\).*/\1****/')
  log "Non-root token created: $MASKED_NON_ROOT_TOKEN"

  if grep -q "^$NON_ROOT_TOKEN_KEY:" "$KEYS_FILE"; then
    if ! sed -i "s/^$NON_ROOT_TOKEN_KEY:.*/$NON_ROOT_TOKEN_KEY: $NON_ROOT_TOKEN/" "$KEYS_FILE"; then
      log "Failed to replace $NON_ROOT_TOKEN_KEY in $KEYS_FILE. Exiting..." "ERROR"
      exit 1
    fi
  else
    if ! echo "$NON_ROOT_TOKEN_KEY: $NON_ROOT_TOKEN" >> "$KEYS_FILE"; then
      log "Failed to append $NON_ROOT_TOKEN_KEY in $KEYS_FIL. Exiting..." "ERROR"
      exit 1
    fi
  fi
  log "Non-root token has been saved."
}

apply_vault_policy
create_approle

log "Fetching ROLE_ID for ${SSH_MANAGER_ROLE_NAME}..."
ROLE_ID=$(vault read -format=json auth/approle/role/${SSH_MANAGER_ROLE_NAME}/role-id \
                              | sed -n 's/.*"role_id": "\([^"]*\)".*/\1/p')
if [ -z "$ROLE_ID" ]; then
  log "Failed to retrieve ROLE_ID for ${SSH_MANAGER_ROLE_NAME}. Exiting..." "ERROR"
  exit 1
fi

log "Fetching SECRET_ID for ${SSH_MANAGER_ROLE_NAME}..."
SECRET_ID=$(vault write -f auth/approle/role/${SSH_MANAGER_ROLE_NAME}/secret-id \
                              | sed -n 's/secret_id[[:space:]]*\([a-zA-Z0-9-]*\).*/\1/p')
if [ -z "$SECRET_ID" ]; then
  log "Failed to retrieve SECRET_ID for ${SSH_MANAGER_ROLE_NAME}. Exiting..." "ERROR"
  exit 1
fi

log "Creating non-root token with ${SSH_KEY_POLICY_NAME} policy..."
NON_ROOT_TOKEN=$(vault write -format=json auth/approle/login \
                             role_id="$ROLE_ID" \
                             secret_id="$SECRET_ID" \
                             | grep '"client_token"' \
                             | sed 's/.*"client_token": "\(.*\)",/\1/')

if [ -z "$NON_ROOT_TOKEN" ]; then
  log "Failed to create non-root token. Exiting..." "ERROR"
  exit 1
fi

update_keys_file
