
Folder structure of the secrets directory in Vault Server:

```
vault_server/secrets/
└── auth
    ├── admin
    │   ├── root
    │   │   └── vault_token
    │   └── unseal_keys
    │       └── keys
    └── ssh_manager_role
        ├── role_id
        ├── secret_id
        └── vault_token

5 directories, 5 files
```

The main directory on host will be `vault_server/secrets/`, whereas it'll be `/vault/secrets` inside the container.

To see the full directory structure, comment out the `vault_ssh_manager_role:/vault/secrets/auth/${SSH_MANAGER_ROLE_NAME}` in
docker-compose.yml, as the named volumes won't show the files in explorer.