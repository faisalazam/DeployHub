# Listener Configuration (for development mode)
listener "tcp" {
  tls_disable = 1                 # Disable TLS (use TLS in production)
  address     = "127.0.0.1:${VAULT_EXTERNAL_PORT}"  # Binding Vault to only localhost network interface
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
disable_mlock = true
