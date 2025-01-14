#!/bin/sh

log() {
  log_level="${2:-INFO}" # Default to INFO if no log level is provided
  echo "$(date --utc '+%Y-%m-%dT%H:%M:%S.%3NZ') [$log_level] $1"
}

log "NOTE: THIS SCRIPT RUNS ON THE HOST..."

# TODO: Store the passphrase somewhere secure.
PASSPHRASE="your_secure_passphrase"

CONFIG_DIR="certs/config"
DATABASE_DIR="certs/database"

BASE_DIR="certs/vaultCA"
ROOT_CA_DIR="$BASE_DIR/root"
INTERMEDIATE_DIR="$BASE_DIR/intermediate"
INTERMEDIATE_CA_CSR="$INTERMEDIATE_DIR/temp/intermediate.csr"
COMBINED_NON_LEAF_CERTS_TEMP_FILE="$BASE_DIR/temp/combined_non_leaf_certs.pem"

export ROOT_CA_CERT="$ROOT_CA_DIR/cacert.pem"
export ROOT_CA_KEY="$ROOT_CA_DIR/private/cakey.pem"
export ROOT_DATABASE_FILE="$DATABASE_DIR/root/root_ca.db"
export ROOT_SERIAL_FILE="$DATABASE_DIR/root/root_ca.serial"

export INTERMEDIATE_CA_CERT="$INTERMEDIATE_DIR/cacert.pem"
export INTERMEDIATE_CA_KEY="$INTERMEDIATE_DIR/private/intermediate_key.pem"
export INTERMEDIATE_DATABASE_FILE="$DATABASE_DIR/intermediate/intermediate_ca.db"
export INTERMEDIATE_SERIAL_FILE="$DATABASE_DIR/intermediate/intermediate_ca.serial"

export RSA_KEY_SIZE=4096
export ROOT_CERT_EXPIRY_DAYS=7300
export INTERMEDIATE_CERT_EXPIRY_DAYS=730

create_serial_file() {
  FILE_PATH="$1"
  if ! [ -f "$FILE_PATH" ]; then
    echo '01' > "$FILE_PATH"
    log "Created $FILE_PATH serial file with initial value 01"
  fi
}

create_db_file() {
  FILE_PATH="$1"
  if ! [ -f "$FILE_PATH" ]; then
    touch "$FILE_PATH"
    log "Created $FILE_PATH file"
  fi
}

create_dirs_and_files() {
  log "Create necessary directories and files"
  # Ensure directories for root/intermediate/server/agent certificates are created dynamically
  if [ -n "$1" ]; then
    CERT_TYPE=$1

    if [ "$CERT_TYPE" = "root" ]; then
      mkdir -p "$BASE_DIR/temp" \
               "$DATABASE_DIR/root" \
               "$ROOT_CA_DIR/private"
      create_db_file "$ROOT_DATABASE_FILE"
      create_serial_file "$ROOT_SERIAL_FILE"
      log "Created directories for root ca"
    elif [ "$CERT_TYPE" = "intermediate" ]; then
      mkdir -p "$DATABASE_DIR/intermediate" \
               "$INTERMEDIATE_DIR/temp" \
               "$INTERMEDIATE_DIR/private" \
               "$INTERMEDIATE_DIR/signedcerts"
      create_db_file "$INTERMEDIATE_DATABASE_FILE"
      create_serial_file "$INTERMEDIATE_SERIAL_FILE"
      log "Created directories for intermediate ca"
    else
      mkdir -p "$BASE_DIR/$CERT_TYPE/temp" \
               "$BASE_DIR/$CERT_TYPE/signedcerts"
      log "Created directories for $CERT_TYPE"
    fi
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

  create_dirs_and_files "root"

  log "Generate the root certificate"
  if ! SIGNED_CERTS_DIR="" openssl req -x509 -newkey rsa:$RSA_KEY_SIZE \
      -out "$ROOT_CA_CERT" -outform PEM -days $ROOT_CERT_EXPIRY_DAYS \
      -keyout "$ROOT_CA_KEY" \
      -passout pass:$PASSPHRASE \
      -config "$CONFIG_DIR/root_ca.cnf" -quiet; then
    log "Failed to generate root certificate" "ERROR"
    exit 1
  fi
  verify_root_certificate
  log "Root certificate generated successfully"
}

generate_intermediate_certificate() {
  if [ -f "$INTERMEDIATE_CA_CERT" ] && [ -f "$INTERMEDIATE_CA_KEY" ]; then
    log "Intermediate certificate already exists. Skipping generation process." "INFO"
    return
  fi

  create_dirs_and_files "intermediate"

  log "Generate the intermediate certificate key"
  if ! openssl genpkey -algorithm RSA -out "$INTERMEDIATE_CA_KEY" -pkeyopt rsa_keygen_bits:$RSA_KEY_SIZE -quiet; then
    log "Failed to generate intermediate CA key" "ERROR"
    exit 1
  fi

  SIGNED_CERTS_DIR="$INTERMEDIATE_DIR/signedcerts"
  log "Generate the intermediate certificate signing request (CSR)"
  if ! SIGNED_CERTS_DIR="$SIGNED_CERTS_DIR" openssl req -new -key "$INTERMEDIATE_CA_KEY" -out "$INTERMEDIATE_CA_CSR" \
      -passin pass:$PASSPHRASE -config "$CONFIG_DIR/intermediate.cnf"; then
    log "Failed to generate intermediate CSR" "ERROR"
    exit 1
  fi

  log "Sign the intermediate certificate with the root certificate"
  if ! SIGNED_CERTS_DIR="$SIGNED_CERTS_DIR" openssl ca -in "$INTERMEDIATE_CA_CSR" -out "$INTERMEDIATE_CA_CERT" \
      -cert "$ROOT_CA_CERT" -keyfile "$ROOT_CA_KEY" \
      -passin pass:$PASSPHRASE -config "$CONFIG_DIR/root_ca.cnf" -batch; then
    log "Failed to sign intermediate certificate with root CA" "ERROR"
    exit 1
  fi

  verify_certificate "intermediate" "$INTERMEDIATE_CA_CERT" "$ROOT_CA_CERT"
  clean_temp_files "$INTERMEDIATE_DIR"
  log "Intermediate certificate generated and signed by root certificate"
}

generate_key_and_request() {
  CERT_TYPE=$1
  SERVER_DIR=$2
  CONFIG_FILE=$3
  COMMON_NAME=$4
  TEMP_KEY="$SERVER_DIR/temp/tempkey.pem"
  TEMP_REQ="$SERVER_DIR/temp/tempreq.pem"

  log "Generate the key and request for $CERT_TYPE using $CONFIG_FILE"
  if ! CN="$COMMON_NAME" openssl req \
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

sign_certificate_with_intermediate_ca() {
  SERVER_DIR=$1
  TEMP_REQ="$SERVER_DIR/temp/tempreq.pem"
  SERVER_CERT="$SERVER_DIR/server_crt.pem"
  SIGNED_CERTS_DIR="$SERVER_DIR/signedcerts"

  log "Sign the certificate for $SERVER_DIR with intermediate CA"
  if ! SIGNED_CERTS_DIR="$SIGNED_CERTS_DIR" openssl ca -in "$TEMP_REQ" \
      -out "$SERVER_CERT" \
      -cert "$INTERMEDIATE_CA_CERT" \
      -keyfile "$INTERMEDIATE_CA_KEY" \
      -passin pass:$PASSPHRASE -config "$CONFIG_DIR/intermediate_signing.cnf" -batch; then
    log "Failed to sign the certificate for $SERVER_DIR with intermediate CA" "ERROR"
    exit 1
  fi
  log "$SERVER_DIR certificate signed successfully"
}

combine_certificates_into_full_chain() {
  SERVER_DIR=$1
  SERVER_CERT="$SERVER_DIR/server_crt.pem"
  FULL_CHAIN="$SERVER_DIR/full_chain.pem"

  log "Combine server certificate, intermediate certificate, and root certificate into the full chain for $SERVER_DIR"
  if ! cat "$SERVER_CERT" "$INTERMEDIATE_CA_CERT" "$ROOT_CA_CERT" > "$FULL_CHAIN"; then
    log "Failed to combine server certificate, intermediate certificate, and root certificate for $SERVER_DIR" "ERROR"
    exit 1
  fi
  log "$SERVER_DIR full chain certificate created successfully"
}

combined_non_leaf_certs_into_temp_ca() {
  log "Combine root CA and intermediate CA certificates into a temporary CA file"
  if ! cat "$ROOT_CA_CERT" "$INTERMEDIATE_CA_CERT" > "$COMBINED_NON_LEAF_CERTS_TEMP_FILE"; then
    log "Failed to combine root $ROOT_CA_CERT CA and intermediate $INTERMEDIATE_CA_CERT CA certificates" "ERROR"
    exit 1
  fi
  log "Temporary CA file created successfully at $COMBINED_NON_LEAF_CERTS_TEMP_FILE"
}

verify_certificate() {
  CERT_TYPE=$1
  CERT_PATH=$2
  CA_CERT_PATH=$3

#  log "Verifying the Issuer of $CERT_PATH certificate is actually $CA_CERT_PATH"
#  if ! openssl verify -no-CAfile -no-CApath -partial_chain "$CA_CERT_PATH" "$CERT_PATH"; then
#    log "$CERT_TYPE certificate verification failed" "ERROR"
#    exit 1
#  fi

  log "Verifying the $CERT_TYPE certificate at $CERT_PATH"
  if ! eval openssl verify -CAfile "$COMBINED_NON_LEAF_CERTS_TEMP_FILE" "$CERT_PATH"; then
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
  COMMON_NAME=$2
  SERVER_DIR="$BASE_DIR/$CERT_TYPE"
  CONFIG_FILE="$CONFIG_DIR/$CERT_TYPE.cnf"

  if [ -f "$SERVER_DIR/server_crt.pem" ]; then
    log "$CERT_TYPE certificate already exists. Skipping generation and signing process." "INFO"
    return
  fi

  create_dirs_and_files "$CERT_TYPE"
  generate_key_and_request "$CERT_TYPE" "$SERVER_DIR" "$CONFIG_FILE" "$COMMON_NAME"
  extract_private_key "$SERVER_DIR"
  sign_certificate_with_intermediate_ca "$SERVER_DIR"
  combine_certificates_into_full_chain "$SERVER_DIR"
  verify_certificate "server" "$SERVER_DIR/server_crt.pem" "$ROOT_CA_CERT"
  verify_certificate "full chain" "$SERVER_DIR/full_chain.pem" "$ROOT_CA_CERT"
  clean_temp_files "$SERVER_DIR"

  log "$CERT_TYPE certificate generation and signing process completed successfully"
}

generate_root_certificate
generate_intermediate_certificate
combined_non_leaf_certs_into_temp_ca
generate_certificate "server" "vault_server"
generate_certificate "agent" "vault_agent"

log "Clean up after generating all leaf certs..."
clean_temp_files "$BASE_DIR"
