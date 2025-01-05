# Listener Configuration (for development mode)
listener "tcp" {
  #TODO: Enable TLS and add certificate
  tls_disable = 1                 # Disable TLS (use TLS in production)
  #TODO: Bind it to more specific IP (e.g. 127.0.0.1) instead of just 0.0.0.0
  address     = "0.0.0.0:${VAULT_EXTERNAL_PORT}"  # Binding Vault to only localhost network interface
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
