# Listener Configuration (for development mode)
listener "tcp" {
  tls_disable = 1
  address = "127.0.0.1:8300"
  cluster_address = "0.0.0.0:8201"
}

# API Address Configuration
api_addr = "http://127.0.0.1:8300"

# Disable Mlock for development
disable_mlock = true

# Storage Backend Configuration (using file storage)
storage "file" {
  path = "/vault/data"
}
