#!/bin/sh

# Activate the virtual environment to ensures that the ansible, ansible-lint, and pytest commands are available
. /opt/venv/bin/activate

# Run pre-playbook checks for best practices and syntax
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
