# Listener Configuration (for development mode)
listener "tcp" {
  # TODO: Bind it to more specific IP (e.g. 127.0.0.1) instead of just 0.0.0.0
  # NOTE: Web interface doesn't work if address is set to 127.0.0.1
  address       = "0.0.0.0:${VAULT_EXTERNAL_PORT}"  # Binding Vault to all network interfaces
  tls_key_file  = "/vault/certs/server.key"
  tls_cert_file = "/vault/certs/intermediate_and_leaf_chain.bundle"
  ######## For mTLS start ##################
  # NOTE: Once mTLS is enabled, accessing https://127.0.0.1:8200 from browser will
  # require adding the certificate from where you are hitting https://127.0.0.1:8200.
  # Otherwise, you'll get the ERR_BAD_SSL_CLIENT_AUTH_CERT error.
  tls_client_ca_file = "/vault/certs/ca.crt"
  tls_require_and_verify_client_cert = "${TLS_REQUIRE_AND_VERIFY_CLIENT_CERT}"
  ######## For mTLS end ####################
}

# Enable the Raft storage backend
storage "raft" {
  path    = "/vault/raft"    # Directory to store Raft data
  node_id = "raft_node_1"    # Unique node ID for this instance
}

# Cluster communication address (use 8201 for internal cluster communication)
cluster_addr = "https://127.0.0.1:8201" # Cluster address for Raft communication

# API Address Configuration
api_addr = "https://127.0.0.1:8200"  # Internal Vault API address

# Disable Mlock for development
disable_mlock = false

# Enable Vault UI (TODO: web access doesn't work when server has started in dev mode)
ui = true
