# Vault Agent Configuration for AppRole Authentication

# Define the Vault address where the Vault server is located.
# TODO: Enable TLS
vault {
  address = "${VAULT_ADDR}"
}

# The token storage, used for storing the token retrieved by the agent.
storage "file" {
  path = "${VAULT_AGENT_ROLE_AUTH_DIR}/vault_token" # File where the Vault token will be stored.
}

# Define how frequently to renew the token, and the TTL (time-to-live).
auto_auth {
  method "approle" {
    config = {
      path = "auth/approle/login"
      policies = ["default"]  # Specify the Vault policies to apply.
      ttl = "1h"              # Token TTL.
      remove_secret_id_file_after_reading = false
      role_id_file_path   = "${VAULT_SERVER_ROLE_AUTH_DIR}/role_id"
      secret_id_file_path = "${VAULT_SERVER_ROLE_AUTH_DIR}/secret_id"
    }
  }

  # The agent will automatically authenticate on start and refresh periodically.
  sink "file" {
    config = {
      path = "${VAULT_AGENT_ROLE_AUTH_DIR}/vault_token"  # Path to store the Vault token.
    }
  }
}

# Cache token and secrets on disk.
cache "file" {
  path = "${VAULT_AGENT_ROLE_AUTH_DIR}/.vault_token_cache"
}

# # A listener block allows the Vault Agent to expose secrets over an HTTP API,
# # enabling applications to fetch secrets dynamically. So, add either template or listener block.
# # This will expose an HTTP endpoint (on port 8201 in this example) where secrets can be queried.
# listener "tcp" {
#   address = "127.0.0.1:8201"
#   tls_disable = true
# }

# Monitor Vault Agent's health status to ensure it stays healthy.
# If Vault is down or the token is invalid, it will attempt to authenticate again.
exit_after_auth = false
