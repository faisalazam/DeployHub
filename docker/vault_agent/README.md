
Folder structure of the secrets directory in Vault Agent:

```
vault_agent/secrets/
├── agent
│   ├── auth
│   │   └── ssh_manager_role
│   │       └── vault_token
│   ├── config
│   │   └── vault_agent.hcl
│   └── ssh_keys
│       ├── ansible
│       │   ├── id_rsa
│       │   ├── id_rsa.pub
│       │   └── linux_explicit_ssh_keys_host.pub
│       └── local
│           └── linux_explicit_ssh_keys_host
│               ├── id_rsa
│               └── id_rsa.pub
└── server
    └── auth
        └── ssh_manager_role
            ├── role_id
            ├── secret_id
            └── vault_token

11 directories, 11 files
```

The main directory on host will be `vault_agent/secrets/`, whereas it'll be `/vault/secrets` inside the container.

To see the full directory structure, replace the `vault_ssh_manager_role:${VAULT_SERVER_ROLE_AUTH_DIR}:ro` in
docker-compose.yml with `../vault_server/secrets/server/auth/${SSH_MANAGER_ROLE_NAME}:${VAULT_SERVER_ROLE_AUTH_DIR}:ro`,
as the named volumes won't show the files in explorer.


```shell
curl -k --cert /vault/certs/agent_cert.pem --key /vault/certs/agent.key https://vault_server:8200/v1/sys/health
```

Verify mTLS:

```shell
curl -v --cacert /vault/certs/ca.crt https://vault_server:8200
curl -v --cacert /vault/certs/ca.crt --cert /vault/certs/agent_cert.bundle --key /vault/certs/agent.key https://vault_server:8200
curl -v --cacert /vault/certs//vault/certs/intermediate_and_leaf_chain.bundle --cert /vault/certs/agent_cert.bundle --key /vault/certs/agent.key https://vault_server:8200

openssl s_client -connect vault_server:8200 -CAfile /vault/certs/ca.crt
openssl s_client -connect vault_server:8200 -CAfile /vault/certs/ca.crt -cert /vault/certs/agent_cert.bundle -key /vault/certs/agent.key
```
