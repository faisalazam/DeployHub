#!/bin/sh

log() {
  log_level="${2:-INFO}" # Default to INFO if no log level is provided
  echo "$(date --utc '+%Y-%m-%dT%H:%M:%S.%3NZ') [$log_level] $1"
}

log "NOTE: THIS SCRIPT RUNS ON THE HOST..."

# TODO: Store the passphrase somewhere secure.
ROOT_PASSPHRASE="your_root_secure_passphrase"
INTERMEDIATE_PASSPHRASE="your_intermediate_secure_passphrase"

SCRIPT_DIR=$(dirname "$0")
CERTS_DIR="$SCRIPT_DIR/../certs"
DATABASE_DIR="$CERTS_DIR/ca_database"
CONFIG_DIR="$SCRIPT_DIR/../openssl/config"

CA_DIR="$CERTS_DIR/certificate_authority"
ROOT_CA_DIR="$CA_DIR/root"
CERT_CHAIN="$CA_DIR/certificate_chains"
LEAF_CERTS_DIR="$CERTS_DIR/end_entity"
INTERMEDIATE_DIR="$CA_DIR/intermediate"
INTERMEDIATE_CA_CSR="$INTERMEDIATE_DIR/temp/intermediate.csr"
ROOT_AND_INTERMEDIATE_CHAIN="$CERT_CHAIN/root_and_intermediate_chain.bundle"

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

set_permissions() {
  FILE_PATH="$1"
  PERMISSIONS="$2"
  if chmod "$PERMISSIONS" "$FILE_PATH"; then
    log "Set permissions $PERMISSIONS for $FILE_PATH"
  else
    log "Error: Failed to set permissions $PERMISSIONS for $FILE_PATH"
    exit 1
  fi
}

create_serial_file() {
  FILE_PATH="$1"
  if ! [ -f "$FILE_PATH" ]; then
    echo '01' > "$FILE_PATH"
    log "Created $FILE_PATH serial file with initial value 01"
    set_permissions "$FILE_PATH" "644"
  fi
}

create_db_file() {
  FILE_PATH="$1"
  if ! [ -f "$FILE_PATH" ]; then
    touch "$FILE_PATH"
    log "Created $FILE_PATH file"
    set_permissions "$FILE_PATH" "600"
  fi
}

create_dirs_and_files() {
  log "Create necessary directories and files"
  # Ensure directories for root/intermediate/server/agent certificates are created dynamically
  if [ -n "$1" ]; then
    CERT_TYPE=$1

    if [ "$CERT_TYPE" = "root" ]; then
      mkdir -p "$DATABASE_DIR/root" \
               "$ROOT_CA_DIR/private"
      create_db_file "$ROOT_DATABASE_FILE"
      create_serial_file "$ROOT_SERIAL_FILE"
      log "Created directories for root ca"
      set_permissions "$ROOT_CA_DIR/private" "700"
    elif [ "$CERT_TYPE" = "intermediate" ]; then
      mkdir -p "$DATABASE_DIR/intermediate" \
               "$INTERMEDIATE_DIR/temp" \
               "$INTERMEDIATE_DIR/private" \
               "$INTERMEDIATE_DIR/signedcerts"
      create_db_file "$INTERMEDIATE_DATABASE_FILE"
      create_serial_file "$INTERMEDIATE_SERIAL_FILE"
      log "Created directories for intermediate ca"
      set_permissions "$INTERMEDIATE_DIR/private" "700"
    else
      mkdir -p "$LEAF_CERTS_DIR/$CERT_TYPE/temp" \
               "$LEAF_CERTS_DIR/$CERT_TYPE/signedcerts"
      log "Created directories for $CERT_TYPE"
      set_permissions "$LEAF_CERTS_DIR/$CERT_TYPE" "700"
    fi
  fi
}

verify_cert_date_validity() {
  CERT_FILE=$1

  # Get notBefore and notAfter dates from the certificate
  notBefore=$(openssl x509 -in "$CERT_FILE" -noout -startdate | cut -d= -f2)
  notAfter=$(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d= -f2)

  # Convert the dates to Unix timestamps
  notBeforeTimestamp=$(date -d "$notBefore" +%s)
  notAfterTimestamp=$(date -d "$notAfter" +%s)
  currentTimestamp=$(date +%s)

  # Check if current date is within the validity period
  if [ "$currentTimestamp" -lt "$notBeforeTimestamp" ] || [ "$currentTimestamp" -gt "$notAfterTimestamp" ]; then
    log "$CERT_FILE certificate is expired or not yet valid" "ERROR"
    exit 1
  fi
}

verify_root_certificate() {
  log "Validating the root certificate"
  # Verify that the root certificate is self-signed (issuer matches subject)
  if ! openssl x509 -in "$ROOT_CA_CERT" -noout -issuer -subject | awk -F '=' '
      /issuer/ {issuer=$NF}
      /subject/ {subject=$NF}
      END {exit !(issuer == subject)}
  '; then
    log "Root certificate is not self-signed (issuer does not match subject)" "ERROR"
    exit 1
  fi

  verify_cert_date_validity "$ROOT_CA_CERT"

  # Verify that the root certificate can validate itself
  if ! openssl verify -CAfile "$ROOT_CA_CERT" "$ROOT_CA_CERT" >/dev/null 2>&1; then
    log "Root certificate failed self-verification" "ERROR"
    exit 1
  fi
  log "Root certificate validation successful"
}

generate_root_certificate() {
  if [ -f "$ROOT_CA_CERT" ] && [ -f "$ROOT_CA_KEY" ]; then
    log "Root certificate already exists. Skipping generation process."
    return
  fi

  create_dirs_and_files "root"

  log "Generate the root certificate"
  if ! SIGNED_CERTS_DIR="" openssl req -x509 -newkey rsa:$RSA_KEY_SIZE \
          -out "$ROOT_CA_CERT" -outform PEM -days $ROOT_CERT_EXPIRY_DAYS \
          -keyout "$ROOT_CA_KEY" \
          -passout pass:$ROOT_PASSPHRASE \
          -config "$CONFIG_DIR/root_ca.cnf" -quiet > /dev/null 2>&1; then
    log "Failed to generate root certificate" "ERROR"
    exit 1
  fi
  verify_root_certificate
  log "Root certificate generated successfully"
  set_permissions "$ROOT_CA_KEY" "644"
  set_permissions "$ROOT_CA_CERT" "644"
}

generate_intermediate_certificate() {
  if [ -f "$INTERMEDIATE_CA_CERT" ] && [ -f "$INTERMEDIATE_CA_KEY" ]; then
    log "Intermediate certificate already exists. Skipping generation process."
    return
  fi

  create_dirs_and_files "intermediate"

  log "Generate the intermediate certificate key"
  if ! openssl genpkey -algorithm RSA -out "$INTERMEDIATE_CA_KEY" \
                       -pkeyopt rsa_keygen_bits:$RSA_KEY_SIZE -quiet; then
    log "Failed to generate intermediate CA key" "ERROR"
    exit 1
  fi

  SIGNED_CERTS_DIR="$INTERMEDIATE_DIR/signedcerts"
  log "Generate the intermediate certificate signing request (CSR)"
  if ! SIGNED_CERTS_DIR="$SIGNED_CERTS_DIR" openssl req -new \
          -key "$INTERMEDIATE_CA_KEY" -out "$INTERMEDIATE_CA_CSR" \
          -passin pass:$INTERMEDIATE_PASSPHRASE \
          -config "$CONFIG_DIR/intermediate.cnf" > /dev/null 2>&1; then
    log "Failed to generate intermediate CSR" "ERROR"
    exit 1
  fi

  log "Sign the intermediate certificate with the root certificate"
  if ! SIGNED_CERTS_DIR="$SIGNED_CERTS_DIR" openssl ca -in "$INTERMEDIATE_CA_CSR" \
          -out "$INTERMEDIATE_CA_CERT" \
          -cert "$ROOT_CA_CERT" -keyfile "$ROOT_CA_KEY" \
          -passin pass:$ROOT_PASSPHRASE \
          -config "$CONFIG_DIR/root_ca.cnf" -batch > /dev/null 2>&1; then
    log "Failed to sign intermediate certificate with root CA" "ERROR"
    exit 1
  fi

  verify_cert_date_validity "$INTERMEDIATE_CA_CERT"
  verify_certificate "intermediate" "$INTERMEDIATE_CA_CERT"
  clean_temp_files "$INTERMEDIATE_DIR"
  log "Intermediate certificate generated and signed by root certificate"
  set_permissions "$INTERMEDIATE_CA_KEY" "644"
  set_permissions "$INTERMEDIATE_CA_CERT" "644"
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
          -passout pass:$INTERMEDIATE_PASSPHRASE \
          -config "$CONFIG_FILE" -quiet > /dev/null 2>&1; then
      log "Failed to generate temporary key and certificate request for $CERT_TYPE" "ERROR"
      exit 1
  fi
  log "$CERT_TYPE temporary key and certificate request generated successfully"
  set_permissions "$TEMP_KEY" "600"
  set_permissions "$TEMP_REQ" "644"
}

extract_private_key() {
  SERVER_DIR=$1
  TEMP_KEY="$SERVER_DIR/temp/tempkey.pem"
  SERVER_KEY="$SERVER_DIR/private_key.pem"

  log "Extract the private key for $SERVER_DIR"
  if ! openssl rsa -in "$TEMP_KEY" -out "$SERVER_KEY" \
                   -passin pass:$INTERMEDIATE_PASSPHRASE; then
    log "Failed to extract the private key" "ERROR"
    exit 1
  fi
  log "Private key extracted successfully"
  set_permissions "$SERVER_KEY" "600"
}

sign_certificate_with_intermediate_ca() {
  SERVER_DIR=$1
  TEMP_REQ="$SERVER_DIR/temp/tempreq.pem"
  SERVER_CERT="$SERVER_DIR/certificate.pem"
  SIGNED_CERTS_DIR="$SERVER_DIR/signedcerts"

  log "Sign the certificate for $SERVER_DIR with intermediate CA"
  if ! SIGNED_CERTS_DIR="$SIGNED_CERTS_DIR" openssl ca -in "$TEMP_REQ" \
          -out "$SERVER_CERT" \
          -cert "$INTERMEDIATE_CA_CERT" \
          -keyfile "$INTERMEDIATE_CA_KEY" \
          -passin pass:$INTERMEDIATE_PASSPHRASE \
          -config "$CONFIG_DIR/intermediate_signing.cnf" -batch > /dev/null 2>&1; then
    log "Failed to sign the certificate for $SERVER_DIR with intermediate CA" "ERROR"
    exit 1
  fi
  log "$SERVER_DIR certificate signed successfully"
  set_permissions "$SERVER_CERT" "644"
}

combined_intermediate_and_leaf_into_chain() {
  SERVER_DIR=$1
  SERVER_CERT="$SERVER_DIR/certificate.pem"
  FULL_CHAIN="$SERVER_DIR/intermediate_and_leaf_chain.bundle"

  log "Combine server certificate, and intermediate certificate into the chain for $SERVER_DIR"
  if ! cat "$SERVER_CERT" "$INTERMEDIATE_CA_CERT" > "$FULL_CHAIN"; then
    log "Failed to combine server certificate, and intermediate certificate for $SERVER_DIR" "ERROR"
    exit 1
  fi
  log "$SERVER_DIR chain certificate created successfully"
  set_permissions "$FULL_CHAIN" "644"
}

combined_root_and_intermediate_into_chain() {
  if [ -f "$ROOT_AND_INTERMEDIATE_CHAIN" ]; then
    log "Root and intermediate chain already exists. Skipping combining top level certificates."
    return
  fi

  log "Combine root CA and intermediate CA certificates into a chain file"
  mkdir -p "$CERT_CHAIN"
  if ! cat "$ROOT_CA_CERT" "$INTERMEDIATE_CA_CERT" > "$ROOT_AND_INTERMEDIATE_CHAIN"; then
    log "Failed to combine root $ROOT_CA_CERT CA and intermediate $INTERMEDIATE_CA_CERT CA certificates" "ERROR"
    exit 1
  fi
  log "Root and intermediate chain file created successfully at $ROOT_AND_INTERMEDIATE_CHAIN"
  set_permissions "$ROOT_AND_INTERMEDIATE_CHAIN" "644"
}

verify_certificate() {
  CERT_TYPE=$1
  CERT_PATH=$2
  VERIFY_WITH=$ROOT_AND_INTERMEDIATE_CHAIN

  if [ "$CERT_TYPE" = "intermediate" ]; then
    VERIFY_WITH=$ROOT_CA_CERT
  fi

  log "Verifying the $CERT_TYPE certificate at $CERT_PATH with $VERIFY_WITH"
  # Chain of trust verification
  if ! openssl verify -CAfile "$VERIFY_WITH" "$CERT_PATH" > /dev/null 2>&1; then
    log "$CERT_TYPE certificate verification failed" "ERROR"
    exit 1
  fi

  # Date validity check
  if ! openssl x509 -in "$CERT_PATH" -noout -checkend 0 > /dev/null 2>&1; then
    log "$CERT_TYPE certificate is expired or not yet valid" "ERROR"
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
  SERVER_DIR="$LEAF_CERTS_DIR/$CERT_TYPE"
  CONFIG_FILE="$CONFIG_DIR/$CERT_TYPE.cnf"

  if [ -f "$SERVER_DIR/certificate.pem" ]; then
    log "$CERT_TYPE certificate already exists. Skipping generation and signing process."
    return
  fi

  create_dirs_and_files "$CERT_TYPE"
  generate_key_and_request "$CERT_TYPE" "$SERVER_DIR" "$CONFIG_FILE" "$COMMON_NAME"
  extract_private_key "$SERVER_DIR"
  sign_certificate_with_intermediate_ca "$SERVER_DIR"
  combined_intermediate_and_leaf_into_chain "$SERVER_DIR"
  verify_cert_date_validity "$SERVER_DIR/certificate.pem"
  verify_certificate "server" "$SERVER_DIR/certificate.pem"
  verify_certificate "trust chain" "$SERVER_DIR/intermediate_and_leaf_chain.bundle"
  clean_temp_files "$SERVER_DIR"

  log "$CERT_TYPE certificate generation and signing process completed successfully"
}

generate_root_certificate
generate_intermediate_certificate
combined_root_and_intermediate_into_chain
generate_certificate "server" "vault_server"
generate_certificate "agent" "vault_agent"
