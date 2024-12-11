Profiles:

When the default profile is active, all services (ansible, linux_ssh_pass_host, linux_ssh_keys_host) will run.
When CI profile is active, only the ansible service will run.

How to Run:

To start all services (e.g. local development):
`docker-compose up`

To start all services (e.g. local development):
`COMPOSE_PROFILES=default docker-compose up`

To start only the ansible service (e.g. CI):
`COMPOSE_PROFILES=CI docker-compose up`

This setup ensures flexibility for local development and CI pipelines without duplicating configuration.

Testing the SSH Connection
From the ansible service, verify the SSH connection manually using the private key:
`docker exec -it ansible ssh -i /root/.ssh/id_rsa root@linux_ssh_keys_host -o StrictHostKeyChecking=no`