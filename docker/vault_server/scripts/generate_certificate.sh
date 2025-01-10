#!/bin/sh

. ./scripts/common.sh

log "NOTE: THIS SCRIPT RUNS ON THE HOST..."

BASE_DIR="certs/vaultCA"
CONFIG_DIR="certs/config"
DATABASE_DIR="$CONFIG_DIR/database"
# TODO: Store the passphrase somewhere secure.
PASSPHRASE="your_secure_passphrase"
ROOT_CA_KEY="$BASE_DIR/private/cakey.pem"
ROOT_CA_CERT="$BASE_DIR/cacert.pem"
RSA_KEY_SIZE=4096
CERT_EXPIRY_DAYS=1825

create_dirs_and_files() {
  log "Create necessary directories and files"

  # Create directories for the root certificate
  mkdir -p "$BASE_DIR/private" "$DATABASE_DIR"

  # Ensure directories for server/agent certificates are created dynamically
  if [ -n "$1" ]; then
    CERT_TYPE=$1
    mkdir -p "$BASE_DIR/$CERT_TYPE/signedcerts" "$BASE_DIR/$CERT_TYPE/temp"
    log "Created directories for $CERT_TYPE"
  fi

  if ! [ -f "$DATABASE_DIR/serial" ]; then
    echo '01' > "$DATABASE_DIR/serial"
    log "Created serial file with initial value 01"
  fi

  if ! [ -f "$DATABASE_DIR/index.txt" ]; then
    touch "$DATABASE_DIR/index.txt"
    log "Created index.txt file"
  fi
}

verify_root_certificate() {
  log "Validating the root certificate"
  if ! openssl x509 -in "$ROOT_CA_CERT" -noout -text | grep -q "Certificate:"; then
    log "Root certificate validation failed" "ERROR"
    exit 1
  fi
  log "Root certificate validation successful"
}

generate_root_certificate() {
  if [ -f "$ROOT_CA_CERT" ] && [ -f "$ROOT_CA_KEY" ]; then
    log "Root certificate already exists. Skipping generation process." "INFO"
    return
  fi

  create_dirs_and_files

  log "Generate the root certificate"
  if ! openssl req -x509 -newkey rsa:$RSA_KEY_SIZE \
      -out "$ROOT_CA_CERT" -outform PEM -days $CERT_EXPIRY_DAYS \
      -keyout "$ROOT_CA_KEY" \
      -passout pass:$PASSPHRASE \
      -config "$CONFIG_DIR/caconfig.cnf" -quiet; then
    log "Failed to generate root certificate" "ERROR"
    exit 1
  fi
  verify_root_certificate
  log "Root certificate generated successfully"
}

generate_key_and_request() {
  CERT_TYPE=$1
  SERVER_DIR=$2
  CONFIG_FILE=$3
  COMMON_NAME="localhost"
  TEMP_KEY="$SERVER_DIR/temp/tempkey.pem"
  TEMP_REQ="$SERVER_DIR/temp/tempreq.pem"

  RANDOM_UID=$(uuidgen)
  log "Generate the key and request for $CERT_TYPE using $CONFIG_FILE"
  if ! CN="$COMMON_NAME" UID="$RANDOM_UID" openssl req \
        -newkey rsa:$RSA_KEY_SIZE \
        -keyout "$TEMP_KEY" -keyform PEM \
        -out "$TEMP_REQ" -outform PEM \
        -passout pass:$PASSPHRASE \
        -config "$CONFIG_FILE" -quiet; then
      log "Failed to generate temporary key and certificate request for $CERT_TYPE" "ERROR"
      exit 1
  fi
  log "$CERT_TYPE temporary key and certificate request generated successfully"
}

extract_private_key() {
  SERVER_DIR=$1
  TEMP_KEY="$SERVER_DIR/temp/tempkey.pem"
  SERVER_KEY="$SERVER_DIR/server_key.pem"

  log "Extract the private key for $SERVER_DIR"
  if ! openssl rsa -in "$TEMP_KEY" -out "$SERVER_KEY" \
      -passin pass:$PASSPHRASE; then
    log "Failed to extract the private key" "ERROR"
    exit 1
  fi
  log "Private key extracted successfully"
}

sign_certificate_with_root_ca() {
  SERVER_DIR=$1
  TEMP_REQ="$SERVER_DIR/temp/tempreq.pem"
  SERVER_CERT="$SERVER_DIR/server_crt.pem"

  log "Sign the certificate for $SERVER_DIR with root CA"
  if ! openssl ca -in "$TEMP_REQ" \
      -out "$SERVER_CERT" \
      -config "$CONFIG_DIR/caconfig.cnf" \
      -batch \
      -passin pass:$PASSPHRASE -quiet; then
    log "Failed to sign the certificate for $SERVER_DIR with root CA" "ERROR"
    exit 1
  fi
  log "$SERVER_DIR certificate signed successfully"
}

combine_certificates_into_full_chain() {
  SERVER_DIR=$1
  SERVER_CERT="$SERVER_DIR/server_crt.pem"
  FULL_CHAIN="$SERVER_DIR/full_chain.pem"

  log "Combine server certificate and CA certificate into the full chain for $SERVER_DIR"
  if ! cat "$SERVER_CERT" "$ROOT_CA_CERT" > "$FULL_CHAIN"; then
    log "Failed to combine server certificate and CA certificate for $SERVER_DIR" "ERROR"
    exit 1
  fi
  log "$SERVER_DIR full chain certificate created successfully"
}

verify_certificate() {
  CERT_TYPE=$1
  CERT_PATH=$2
  CA_CERT_PATH=$3

  log "Verifying the $CERT_TYPE certificate at $CERT_PATH"
  if ! openssl verify -CAfile "$CA_CERT_PATH" "$CERT_PATH"; then
    log "$CERT_TYPE certificate verification failed" "ERROR"
    exit 1
  fi
  log "$CERT_TYPE certificate verification successful"
}

clean_temp_files() {
  SERVER_DIR=$1

  log "Cleaning up temporary files for $SERVER_DIR"
  if ! rm -rf "$SERVER_DIR/temp"; then
    log "Failed to remove temp directory for $SERVER_DIR" "ERROR"
    exit 1
  fi
  log "Temporary directory for $SERVER_DIR removed successfully"
}

generate_certificate() {
  CERT_TYPE=$1
  SERVER_DIR="$BASE_DIR/$CERT_TYPE"
  CONFIG_FILE="$CONFIG_DIR/$CERT_TYPE.cnf"

  if [ -f "$SERVER_DIR/server_crt.pem" ]; then
    log "$CERT_TYPE certificate already exists. Skipping generation and signing process." "INFO"
    return
  fi

  create_dirs_and_files "$CERT_TYPE"
  generate_key_and_request "$CERT_TYPE" "$SERVER_DIR" "$CONFIG_FILE"
  extract_private_key "$SERVER_DIR"
  sign_certificate_with_root_ca "$SERVER_DIR"
  combine_certificates_into_full_chain "$SERVER_DIR"
  verify_certificate "server" "$SERVER_DIR/server_crt.pem" "$ROOT_CA_CERT"
  verify_certificate "full chain" "$SERVER_DIR/full_chain.pem" "$ROOT_CA_CERT"
  clean_temp_files "$SERVER_DIR"

  log "$CERT_TYPE certificate generation and signing process completed successfully"
}

generate_root_certificate
generate_certificate "server"
