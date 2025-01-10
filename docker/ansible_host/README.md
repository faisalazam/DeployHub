

```shell
COMPOSE_PROFILES=test ENVIRONMENT=local docker-compose up -d
MSYS_NO_PATHCONV=1 docker exec -e RUN_WITH_CERTIFICATE=false -e ENVIRONMENT=local ansible sh /usr/local/bin/setup.sh
MSYS_NO_PATHCONV=1 docker exec -e RUN_TESTS=true -e ENVIRONMENT=local ansible sh /usr/local/bin/run_tests.sh
MSYS_NO_PATHCONV=1 docker exec -e COMPOSE_PROFILES=test -e ENVIRONMENT=local ansible sh /usr/local/bin/execute_playbooks.sh
MSYS_NO_PATHCONV=1 docker exec -e RUN_TESTS=true -e ENVIRONMENT=local ansible sh /usr/local/bin/post_playbook_checks.sh
```