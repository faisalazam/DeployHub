Profiles:

When the default profile is active, all services (ansible, linux_ssh_pass_host, linux_ssh_keys_host) will run.
When no profile is active, only the ansible service will run.

How to Run:

To start only ansible service:
`docker-compose up`

To start all services (e.g. local development):
`COMPOSE_PROFILES=default docker-compose up`

This setup ensures flexibility for local development and CI pipelines without duplicating configuration.