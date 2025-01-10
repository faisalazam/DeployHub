#!/bin/sh

. ./scripts/common.sh
log "NOTE: THIS SCRIPT RUNS ON THE HOST..."

# Define variables
BASE_DIR="certs/vaultCA"
CONFIG_DIR="certs/config"
# TODO: Store the passphrase somewhere secure.
PASSPHRASE="your_secure_passphrase"
ROOT_CA_KEY="$BASE_DIR/private/cakey.pem"
ROOT_CA_CERT="$BASE_DIR/cacert.pem"
TEMP_KEY="$BASE_DIR/tempkey.pem"
TEMP_REQ="$BASE_DIR/tempreq.pem"
SERVER_KEY="$BASE_DIR/server_key.pem"
SERVER_CERT="$BASE_DIR/server_crt.pem"
FULL_CHAIN="$BASE_DIR/full_chain.pem"

log "Create necessary directories and files"
mkdir -p "$BASE_DIR/signedcerts" "$BASE_DIR/private"

if [ ! -f "$CONFIG_DIR/serial" ]; then
  echo '01' > "$CONFIG_DIR/serial"
fi

if [ ! -f "$CONFIG_DIR/index.txt" ]; then
  touch "$CONFIG_DIR/index.txt"
fi

log "Generate the root certificate"
openssl req -x509 -newkey rsa:2048 \
  -out "$ROOT_CA_CERT" -outform PEM -days 1825 \
  -keyout "$ROOT_CA_KEY" \
  -passout pass:$PASSPHRASE \
  -config "$CONFIG_DIR/caconfig.cnf"

log "Generate the key and request using localhost configuration"
openssl req -newkey rsa:2048 \
  -keyout "$TEMP_KEY" -keyform PEM \
  -out "$TEMP_REQ" -outform PEM \
  -passout pass:$PASSPHRASE \
  -config "$CONFIG_DIR/localhost.cnf"

log "Extract the private key from the temporary key file"
openssl rsa -in "$TEMP_KEY" -out "$SERVER_KEY" \
  -passin pass:$PASSPHRASE

log "Sign the certificate with the root CA configuration"
openssl ca -in "$TEMP_REQ" \
  -out "$SERVER_CERT" \
  -config "$CONFIG_DIR/caconfig.cnf" \
  -batch \
  -passin pass:$PASSPHRASE

log "Combine server certificate and CA certificate into the full chain"
cat "$SERVER_CERT" "$ROOT_CA_CERT" > "$FULL_CHAIN"
