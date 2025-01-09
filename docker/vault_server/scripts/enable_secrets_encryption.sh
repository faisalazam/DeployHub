#!/bin/sh

. /vault/scripts/common.sh

log "Enabling the transit secrets engine..."
if ! vault secrets list | grep -q "transit/"; then
  if ! vault secrets enable transit; then
    log "Failed to enable the transit secrets engine. Exiting..." "ERROR"
    exit 1
  fi
  log "Transit secrets engine has been enabled."
else
  log "Transit secrets engine is already enabled. Skipping..."
fi

log "Creating transit key '$TRANSIT_KEY_NAME'..."
if ! vault read "transit/keys/$TRANSIT_KEY_NAME" > /dev/null 2>&1; then
  if ! vault write -f "transit/keys/$TRANSIT_KEY_NAME"; then
    log "Failed to create transit key '$TRANSIT_KEY_NAME'. Exiting..." "ERROR"
    exit 1
  fi
  log "Transit key '$TRANSIT_KEY_NAME' has been successfully created."
else
  log "Transit key '$TRANSIT_KEY_NAME' already exists. Skipping creation..."
fi
