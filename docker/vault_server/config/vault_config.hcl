# Listener Configuration (for development mode)
listener "tcp" {
  # TODO: Bind it to more specific IP (e.g. 127.0.0.1) instead of just 0.0.0.0
  # NOTE: Web interface doesn't work if address is set to 127.0.0.1
  address       = "0.0.0.0:${VAULT_EXTERNAL_PORT}"  # Binding Vault to all network interfaces
  tls_key_file  = "/vault/certs/server.key"
  tls_cert_file = "/vault/certs/full_chain.pem"
  # tls_client_ca_file  = "/vault/certs/cacert.pem"
}

# Enable the Raft storage backend
storage "raft" {
  path    = "/vault/raft"    # Directory to store Raft data
  node_id = "raft_node_1"    # Unique node ID for this instance
}

# Cluster communication address (use 8201 for internal cluster communication)
cluster_addr = "http://127.0.0.1:8201" # Cluster address for Raft communication

# API Address Configuration
api_addr = "http://127.0.0.1:8200"  # Internal Vault API address

# Disable Mlock for development
# TODO: change this for prod
disable_mlock = true

# Enable Vault UI (TODO: web access doesn't work when server has started in dev mode)
ui = true
