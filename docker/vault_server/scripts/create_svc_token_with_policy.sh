#!/bin/sh

SSH_MANAGER_TOKEN_KEY="SSH_MANAGER_TOKEN"
SSH_MANAGER_ROLE_ID_KEY="SSH_MANAGER_ROLE_ID"
SSH_MANAGER_SECRET_ID_KEY="SSH_MANAGER_SECRET_ID"

. /vault/scripts/common.sh

apply_vault_policy() {
  log "Applying Vault policy..."
  if vault policy read "${SSH_KEY_POLICY_NAME}" > /dev/null 2>&1; then
    log "Vault policy '${SSH_KEY_POLICY_NAME}' already exists. Skipping policy application..."
  else
    if ! vault policy write "${SSH_KEY_POLICY_NAME}" "${SSH_KEY_POLICY_PATH}"; then
      log "Failed to apply Vault policy '${SSH_KEY_POLICY_NAME}'. Exiting..." "ERROR"
      exit 1
    else
      log "Vault policy '${SSH_KEY_POLICY_NAME}' applied successfully."
    fi
  fi
}

create_approle() {
  log "Checking if AppRole ${SSH_MANAGER_ROLE_NAME} already exists..."
  if vault read -format=json auth/approle/role/"${SSH_MANAGER_ROLE_NAME}" > /dev/null 2>&1; then
    log "AppRole ${SSH_MANAGER_ROLE_NAME} already exists. Skipping creation."
  else
  log "Creating AppRole ${SSH_MANAGER_ROLE_NAME} with token_ttl=${TOKEN_TTL} and token_max_ttl=${TOKEN_MAX_TTL}..."
    if ! vault write auth/approle/role/"${SSH_MANAGER_ROLE_NAME}" \
                     policies="${SSH_KEY_POLICY_NAME}" \
                     token_ttl="${TOKEN_TTL}" \
                     token_max_ttl="${TOKEN_MAX_TTL}"; then
    log "Failed to create AppRole ${SSH_MANAGER_ROLE_NAME} with token_ttl=${TOKEN_TTL} and token_max_ttl=${TOKEN_MAX_TTL}. Exiting..." "ERROR"
      exit 1
    fi
  log "AppRole ${SSH_MANAGER_ROLE_NAME} has been created."
  fi
}

apply_vault_policy
create_approle

log "Fetching ROLE_ID for ${SSH_MANAGER_ROLE_NAME}..."
ROLE_ID=$(vault read -format=json auth/approle/role/"${SSH_MANAGER_ROLE_NAME}"/role-id \
                              | sed -n 's/.*"role_id": "\([^"]*\)".*/\1/p')
# TODO: store it somewhere secure instead of the file in the container.
# May be in the CI's credentials manger, AWS KMS etc.
save_key_value_to_file "$SSH_MANAGER_ROLE_ID_KEY" "$ROLE_ID" "${SECRETS_DIR}/auth/${SSH_MANAGER_ROLE_NAME}" "role_id"

log "Fetching SECRET_ID for ${SSH_MANAGER_ROLE_NAME}..."
SECRET_ID=$(vault write -f auth/approle/role/"${SSH_MANAGER_ROLE_NAME}"/secret-id \
                              | sed -n 's/secret_id[[:space:]]*\([a-zA-Z0-9-]*\).*/\1/p')
# TODO: store it somewhere secure instead of the file in the container.
# May be in the CI's credentials manger, AWS KMS etc.
save_key_value_to_file "$SSH_MANAGER_SECRET_ID_KEY" "$SECRET_ID" "${SECRETS_DIR}/auth/${SSH_MANAGER_ROLE_NAME}" "secret_id"

log "Creating 'SSH_MANAGER_TOKEN' token with ${SSH_KEY_POLICY_NAME} policy..."
SSH_MANAGER_TOKEN=$(vault write -format=json auth/approle/login \
                             role_id="$ROLE_ID" \
                             secret_id="$SECRET_ID" \
                             | grep '"client_token"' \
                             | sed 's/.*"client_token": "\(.*\)",/\1/')
# TODO: store it somewhere secure instead of the file in the container.
# May be in the CI's credentials manger, AWS KMS etc.
save_key_value_to_file "$SSH_MANAGER_TOKEN_KEY" "$SSH_MANAGER_TOKEN" "${SECRETS_DIR}/auth/${SSH_MANAGER_ROLE_NAME}" "vault_token"
