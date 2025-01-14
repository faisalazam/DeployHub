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

To see the full directory structure, comment out the
`vault_ssh_manager_role:/vault/secrets/auth/${SSH_MANAGER_ROLE_NAME}` in
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

To enable TLS on Vault Server:

Add the following in the docker compose of vault server:

```yml
    environment:
      VAULT_CACERT: /vault/certs/ca.crt
    volumes:
      - ./certs/vaultCA/cacert.pem:/vault/certs/ca.crt:ro
      - ./certs/vaultCA/server/server_key.pem:/vault/certs/server.key:ro
      - ./certs/vaultCA/server/intermediate_and_leaf_chain.pem:/vault/certs/intermediate_and_leaf_chain.pem:ro
```

and:

```hcl
listener "tcp" {
  address = "0.0.0.0:8200"  # Binding Vault to all network interfaces
  tls_key_file  = "/vault/certs/server.key"
  tls_cert_file = "/vault/certs/intermediate_and_leaf_chain.pem"
}
```

Add the following in the docker compose of vault agent:

```yml
environment:
  VAULT_CACERT: /vault/certs/ca.crt
volumes:
  - ../vault_server/certs/vaultCA/cacert.pem:/vault/certs/ca.crt:ro
```

Additional setting to enable mTLS after setting up the TLS on Vault Server:

Add the following in the docker compose of vault server:

```yml
    environment:
      VAULT_CLIENT_KEY: /vault/certs/agent.key
      VAULT_CLIENT_CERT: /vault/certs/agent.crt
    volumes:
      - ./certs/vaultCA/agent/server_crt.pem:/vault/certs/agent.crt:ro
      - ./certs/vaultCA/agent/server_key.pem:/vault/certs/agent.key:ro
```

So the environment and volume sections may look like:

```yml
    environment:
      VAULT_CACERT: /vault/certs/ca.crt
      VAULT_CLIENT_KEY: /vault/certs/agent.key
      VAULT_CLIENT_CERT: /vault/certs/agent.crt
    volumes:
      - ./certs/vaultCA/cacert.pem:/vault/certs/ca.crt:ro
      - ./certs/vaultCA/agent/server_crt.pem:/vault/certs/agent.crt:ro
      - ./certs/vaultCA/agent/server_key.pem:/vault/certs/agent.key:ro
      - ./certs/vaultCA/server/server_key.pem:/vault/certs/server.key:ro
      - ./certs/vaultCA/server/intermediate_and_leaf_chain.pem:/vault/certs/intermediate_and_leaf_chain.pem:ro
```

and add the following to the listener in the hcl file:

```hcl
tls_client_ca_file = "/vault/certs/ca.crt" # Path to the cert file
tls_require_and_verify_client_cert = "true" 
```

And the full listener block may look like:

```hcl
listener "tcp" {
  address = "0.0.0.0:8200"  # Binding Vault to all network interfaces
  tls_key_file                       = "/vault/certs/server.key"
  tls_cert_file                      = "/vault/certs/intermediate_and_leaf_chain.pem"
  tls_client_ca_file                 = "/vault/certs/ca.crt"
  tls_require_and_verify_client_cert = "true"
}
```

Add the following in the docker compose of vault agent:

```yml
environment:
  VAULT_CLIENT_KEY: /vault/certs/agent_key.pem
  VAULT_CLIENT_CERT: /vault/certs/agent_cert.pem
volumes:
  - ../vault_server/certs/vaultCA/agent/server_key.pem:/vault/certs/agent_key.pem:ro
  - ../vault_server/certs/vaultCA/agent/intermediate_and_leaf_chain.pem:/vault/certs/agent_cert.pem:ro
```

So the environment and volume sections may look like:

```yml
environment:
  VAULT_CACERT: /vault/certs/ca.crt
  VAULT_CLIENT_KEY: /vault/certs/agent_key.pem
  VAULT_CLIENT_CERT: /vault/certs/agent_cert.pem
volumes:
  - ../vault_server/certs/vaultCA/cacert.pem:/vault/certs/ca.crt:ro
  - ../vault_server/certs/vaultCA/agent/server_key.pem:/vault/certs/agent_key.pem:ro
  - ../vault_server/certs/vaultCA/agent/intermediate_and_leaf_chain.pem:/vault/certs/agent_cert.pem:ro
```