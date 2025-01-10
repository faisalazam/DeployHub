
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

Run the `docker/vault_server/scripts/generate_certificate.sh` script from within the `docker/vault_server` directory
before starting the vault server to generate the certs.

```shell
curl --cacert /vault/certs/cacert.pem https://127.0.0.1:8200/v1/sys/health
curl --cacert /vault/certs/cacert.pem https://localhost:8200/v1/sys/health
curl --cacert /vault/certs/cacert.pem https://vault_server:8200/v1/sys/health
curl --cacert /vault/certs/cacert.pem https://172.18.0.1:8200/v1/sys/health

openssl s_client -connect 127.0.0.1:8200 -CAfile /vault/certs/vault-cert.pem

sslscan 127.0.0.1:8200
sslscan localhost:8200
sslscan vault_server:8200
sslscan 172.18.0.1:8200
```