# Listener Configuration (for development mode)
listener "tcp" {
  tls_disable = 1
  address = "127.0.0.1:8300"
}

# Enable the Raft storage backend
storage "raft" {
  path    = "/vault/raft"    # Directory to store Raft data
  node_id = "raft_node_1"    # Unique node ID for this instance
}

# Cluster communication address
cluster_addr = "http://127.0.0.1:8201" # Cluster address for Raft communication

# API Address Configuration
api_addr = "http://127.0.0.1:8300"

# Disable Mlock for development
disable_mlock = true
