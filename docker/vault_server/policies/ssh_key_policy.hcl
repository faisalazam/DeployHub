# Allow access to global Ansible keys
path "secret/data/ssh_keys/*" {
  capabilities = ["create", "update", "read", "delete"]
}

# Allow listing of keys
path "secret/metadata/ssh_keys/*" {
  capabilities = ["list"]
}