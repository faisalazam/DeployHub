#!/bin/sh

. ./scripts/common.sh
log "NOTE: THIS SCRIPT RUNS ON THE HOST..."

BASE_DIR="certs/vaultCA"
SERVER_DIR="$BASE_DIR/server"
CONFIG_DIR="certs/config"
DATABASE_DIR="$CONFIG_DIR/database"
# TODO: Store the passphrase somewhere secure.
PASSPHRASE="your_secure_passphrase"
ROOT_CA_KEY="$BASE_DIR/private/cakey.pem"
ROOT_CA_CERT="$BASE_DIR/cacert.pem"
TEMP_KEY="$SERVER_DIR/temp/tempkey.pem"
TEMP_REQ="$SERVER_DIR/temp/tempreq.pem"
SERVER_KEY="$SERVER_DIR/server_key.pem"
SERVER_CERT="$SERVER_DIR/server_crt.pem"
FULL_CHAIN="$SERVER_DIR/full_chain.pem"

log "Create necessary directories and files"
mkdir -p "$BASE_DIR/private" "$SERVER_DIR/signedcerts" "$SERVER_DIR/temp" "$DATABASE_DIR"

if ! [ -f "$DATABASE_DIR/serial" ]; then
  echo '01' > "$DATABASE_DIR/serial"
  log "Created serial file with initial value 01"
fi

if ! [ -f "$DATABASE_DIR/index.txt" ]; then
  touch "$DATABASE_DIR/index.txt"
  log "Created index.txt file"
fi

log "Generate the root certificate"
if ! openssl req -x509 -newkey rsa:2048 \
  -out "$ROOT_CA_CERT" -outform PEM -days 1825 \
  -keyout "$ROOT_CA_KEY" \
  -passout pass:$PASSPHRASE \
  -config "$CONFIG_DIR/caconfig.cnf"; then
  log "Failed to generate root certificate" "ERROR"
  exit 1
fi
log "Root certificate generated successfully"

log "Generate the key and request using localhost configuration"
if ! openssl req -newkey rsa:2048 \
  -keyout "$TEMP_KEY" -keyform PEM \
  -out "$TEMP_REQ" -outform PEM \
  -passout pass:$PASSPHRASE \
  -config "$CONFIG_DIR/localhost.cnf"; then
  log "Failed to generate temporary key and certificate request" "ERROR"
  exit 1
fi
log "Temporary key and certificate request generated successfully"

log "Extract the private key from the temporary key file"
if ! openssl rsa -in "$TEMP_KEY" -out "$SERVER_KEY" \
  -passin pass:$PASSPHRASE; then
  log "Failed to extract the private key" "ERROR"
  exit 1
fi
log "Private key extracted successfully"

log "Sign the certificate with the root CA configuration"
if ! openssl ca -in "$TEMP_REQ" \
  -out "$SERVER_CERT" \
  -config "$CONFIG_DIR/caconfig.cnf" \
  -batch \
  -passin pass:$PASSPHRASE; then
  log "Failed to sign the certificate with root CA" "ERROR"
  exit 1
fi
log "Certificate signed successfully"

log "Combine server certificate and CA certificate into the full chain"
if ! cat "$SERVER_CERT" "$ROOT_CA_CERT" > "$FULL_CHAIN"; then
  log "Failed to combine server certificate and CA certificate" "ERROR"
  exit 1
fi
log "Full chain certificate created successfully"

log "Cleaning up temporary files"
if ! rm -rf "$SERVER_DIR/temp"; then
  log "Failed to remove temp directory" "ERROR"
  exit 1
fi
log "Temporary directory removed successfully"

log "Certificate generation and signing process completed successfully"
