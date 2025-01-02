# Allow access to global Ansible keys
path "secret/data/ssh_keys/*" {
  capabilities = ["create", "update", "read", "delete"]
}