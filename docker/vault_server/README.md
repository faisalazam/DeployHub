Folder structure of the secrets directory in Vault Server:

```
vault_server/secrets/server
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
`vault_ssh_manager_role:${VAULT_SERVER_ROLE_AUTH_DIR}` in
docker-compose.yml, as the named volumes won't show the files in explorer.

Run the `DeployHub/scripts/generate_certificate.sh` script before starting 
the vault server to generate the certs.

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
      - ../../certs/certificate_authority/intermediate/cacert.pem:/vault/certs/ca.crt:ro
      - ../../certs/end_entity/vault_server/private_key.pem:/vault/certs/server.key:ro
      - ../../certs/end_entity/vault_server/intermediate_and_leaf_chain.bundle:/vault/certs/intermediate_and_leaf_chain.bundle:ro
```

and:

```hcl
listener "tcp" {
  address = "0.0.0.0:8200"  # Binding Vault to all network interfaces
  tls_key_file  = "/vault/certs/server.key"
  tls_cert_file = "/vault/certs/intermediate_and_leaf_chain.bundle"
}
```

Add the following in the docker compose of vault agent:

```yml
environment:
  VAULT_CACERT: /vault/certs/ca.crt
volumes:
  - ../../certs/certificate_authority/intermediate/cacert.pem:/vault/certs/ca.crt:ro
```

Additional setting to enable mTLS after setting up the TLS on Vault Server:

Add the following in the docker compose of vault server:

```yml
    environment:
      VAULT_CLIENT_KEY: /vault/certs/agent.key
      VAULT_CLIENT_CERT: /vault/certs/agent.crt
    volumes:
      - ../../certs/end_entity/vault_agent/certificate.pem:/vault/certs/agent.crt:ro
      - ../../certs/end_entity/vault_agent/private_key.pem:/vault/certs/agent.key:ro
```

So the environment and volume sections may look like:

```yml
    environment:
      VAULT_CACERT: /vault/certs/ca.crt
      VAULT_CLIENT_KEY: /vault/certs/agent.key
      VAULT_CLIENT_CERT: /vault/certs/agent.crt
    volumes:
      - ../../certs/certificate_authority/intermediate/cacert.pem:/vault/certs/ca.crt:ro
      - ../../certs/end_entity/vault_agent/certificate.pem:/vault/certs/agent.crt:ro
      - ../../certs/end_entity/vault_agent/private_key.pem:/vault/certs/agent.key:ro
      - ../../certs/end_entity/vault_server/private_key.pem:/vault/certs/server.key:ro
      - ../../certs/end_entity/vault_server/intermediate_and_leaf_chain.bundle:/vault/certs/intermediate_and_leaf_chain.bundle:ro
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
  tls_cert_file                      = "/vault/certs/intermediate_and_leaf_chain.bundle"
  tls_client_ca_file                 = "/vault/certs/ca.crt"
  tls_require_and_verify_client_cert = "true"
}
```

Add the following in the docker compose of vault agent:

```yml
environment:
  VAULT_CLIENT_KEY: /vault/certs/agent.key
  VAULT_CLIENT_CERT: /vault/certs/agent_cert.bundle
volumes:
  - ../../certs/end_entity/vault_agent/private_key.pem:/vault/certs/agent.key:ro
  - ../../certs/end_entity/vault_agent/intermediate_and_leaf_chain.bundle:/vault/certs/agent_cert.bundle:ro
```

So the environment and volume sections may look like:

```yml
environment:
  VAULT_CACERT: /vault/certs/ca.crt
  VAULT_CLIENT_KEY: /vault/certs/agent.key
  VAULT_CLIENT_CERT: /vault/certs/agent_cert.bundle
volumes:
  - ../../certs/certificate_authority/certificate_chains/root_and_intermediate_chain.bundle:/vault/certs/ca.crt:ro
  - ../../certs/end_entity/vault_agent/private_key.pem:/vault/certs/agent.key:ro
  - ../../certs/end_entity/vault_agent/intermediate_and_leaf_chain.bundle:/vault/certs/agent_cert.bundle:ro
```
