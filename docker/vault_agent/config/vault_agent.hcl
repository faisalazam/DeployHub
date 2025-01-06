# Vault Agent Configuration for AppRole Authentication

# Define the Vault address where the Vault server is located.
vault {
  address = "${VAULT_ADDR}"
}

# The token storage, used for storing the token retrieved by the agent.
storage "file" {
  path = "/vault/secrets/auth/agent/${SSH_MANAGER_ROLE_NAME}/vault_token" # File where the Vault token will be stored.
}

# Define how frequently to renew the token, and the TTL (time-to-live).
auto_auth {
  method "approle" {
    config = {
      path = "auth/approle/login"
      policies = ["default"]  # Specify the Vault policies to apply.
      ttl = "1h"              # Token TTL.
      role_id_file_path   = "/vault/auth/${SSH_MANAGER_ROLE_NAME}/role_id"
      secret_id_file_path = "/vault/auth/${SSH_MANAGER_ROLE_NAME}/secret_id"
    }
  }

  # The agent will automatically authenticate on start and refresh periodically.
  sink "file" {
    config = {
      path = "/vault/secrets/auth/agent/${SSH_MANAGER_ROLE_NAME}/vault_token"  # Path to store the Vault token.
    }
  }
}

# Cache token and secrets on disk.
cache "file" {
  path = "/vault/secrets/auth/agent/${SSH_MANAGER_ROLE_NAME}/.vault_token_cache"
}

template {
  source = "/vault/config/template.ctmpl"
  destination = "/vault/secrets/auth/ansible/ssh_keys/sample_output.json"
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
