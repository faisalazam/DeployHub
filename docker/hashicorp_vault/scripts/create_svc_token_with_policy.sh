#!/bin/sh

SSH_KEY_POLICY_NAME="ssh_key_policy"
SSH_KEY_POLICY_PATH="/vault/policies/ssh_key_policy.hcl"

. /opt/vault/common.sh

log "Applied Vault Policy"
if vault policy read ${SSH_KEY_POLICY_NAME} > /dev/null 2>&1; then
  log "Vault policy '${SSH_KEY_POLICY_NAME}' already exists. Skipping policy application..."
else
  if ! vault policy write ${SSH_KEY_POLICY_NAME} ${SSH_KEY_POLICY_PATH}; then
    log "Failed to apply Vault policy. Exiting..." "ERROR"
    exit 1
  else
    log "Vault policy '${SSH_KEY_POLICY_NAME}' applied successfully."
  fi
fi

log "Applied the following Vault policy"
vault policy read ${SSH_KEY_POLICY_NAME}

log "Creating non-root token with ${SSH_KEY_POLICY_NAME} policy..."
NON_ROOT_TOKEN=$(vault token create -policy="${SSH_KEY_POLICY_NAME}" \
                                    -format=json \
                                    | grep '"client_token"' \
                                    | sed 's/.*"client_token": "\(.*\)",/\1/')

if [ -z "$NON_ROOT_TOKEN" ]; then
  log "Failed to create non-root token." "ERROR"
  exit 1
fi

MASKED_NON_ROOT_TOKEN=$(echo "$NON_ROOT_TOKEN" | sed 's/^\(....\).*/\1****/')
log "Non-root token created: $MASKED_NON_ROOT_TOKEN"

if ! sed -i "${NON_ROOT_TOKEN_LINE}c\Non-root token: $NON_ROOT_TOKEN" "$KEYS_FILE"; then
  log "Failed to update $KEYS_FILE with the non-root token." "ERROR"
  exit 1
fi
log "Non-root token has been saved."