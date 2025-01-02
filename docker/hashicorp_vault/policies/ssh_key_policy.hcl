# Allow access to global Ansible keys
path "secret/data/ssh_keys/ansible" {
  capabilities = ["create", "update", "read", "delete"]
}

# Allow access to environment-specific SSH keys
path "secret/data/ssh_keys/{{identity.entity.metadata.environment}}/*" {
  capabilities = ["create", "update", "read", "delete"]
}
