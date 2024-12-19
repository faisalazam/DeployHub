#!/bin/sh

echo "Executing Ansible playbooks..."

if [ "${COMPOSE_PROFILES}" = "test" ]; then
  echo "Test profile detected. Running Linux playbook only."
  ansible-playbook \
    -i /ansible/inventory/"${ENVIRONMENT}"/hosts.yml \
    /ansible/playbooks/deploy_linux.yml \
    -e ENVIRONMENT="${ENVIRONMENT}"
else
  echo "Non-CI profile detected. Running both Linux and Windows playbooks."
  ansible-playbook \
    -i /ansible/inventory/"${ENVIRONMENT}"/hosts.yml \
    /ansible/playbooks/deploy_linux.yml \
    /ansible/playbooks/deploy_windows.yml \
    -e ENVIRONMENT="${ENVIRONMENT}"
fi
