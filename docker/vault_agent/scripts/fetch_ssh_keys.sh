#!/bin/sh

. /vault/scripts/common.sh

# Fetch the list of machines from Vault
MACHINES=$(vault kv list "secret/ssh_keys/${ENVIRONMENT}" | tail -n +3)  # List keys and ignore the first two lines (headers)

if [ -z "$MACHINES" ]; then
  log "No machines found under secret/ssh_keys/${ENVIRONMENT}. Exiting..."
  exit 1
fi

# Iterate over each machine and create templates dynamically
for MACHINE in $MACHINES; do
  MACHINE_PATH="secret/data/ssh_keys/${ENVIRONMENT}/${MACHINE}"

  # Add template for id_rsa
  cat <<OUTER_EOT >> /vault/secrets/config/vault_agent_resolved.hcl
    template {
      contents = <<INNER_EOT
        {{ with secret "${MACHINE_PATH}" }}
          {{ .Data.data.id_rsa }}
        {{ end }}
      INNER_EOT
      destination = "/vault/secrets/auth/ssh_keys/${ENVIRONMENT}/${MACHINE}/id_rsa"
    }
OUTER_EOT

  # Add template for id_rsa.pub
  cat <<OUTER_EOT >> /vault/secrets/config/vault_agent_resolved.hcl
    template {
      contents = <<INNER_EOT
        {{ with secret "${MACHINE_PATH}" }}
          {{ index .Data.data "id_rsa.pub" }}
        {{ end }}
      INNER_EOT
      destination = "/vault/secrets/auth/ssh_keys/${ENVIRONMENT}/${MACHINE}/id_rsa.pub"
    }
OUTER_EOT
done

log "Restarting Vault agent to apply new templates..."
kill "$AGENT_PID"  # Terminate the running Vault Agent process

# Restart the Vault Agent
vault agent -config=/vault/secrets/config/vault_agent_resolved.hcl &
AGENT_PID=$!  # Capture the new process ID of the Vault Agent

if kill -0 "$AGENT_PID" > /dev/null 2>&1; then
  log "Vault Agent restarted successfully with new templates."
else
  log "Failed to restart Vault Agent. Exiting..." "ERROR"
  exit 1
fi