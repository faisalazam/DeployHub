#!/bin/sh

. /opt/venv/bin/activate
python3 --version
pip show pywinrm
pip show molecule
molecule --version
pytest --version
ansible --version
ansible-playbook --version

echo "RUN_TESTS=${RUN_TESTS}"
echo "ENVIRONMENT=${ENVIRONMENT}"
echo "COMPOSE_PROFILES=${COMPOSE_PROFILES}"
echo "RUN_WITH_CERTIFICATE=${RUN_WITH_CERTIFICATE}"

# Remove any existing known hosts entry for linux_ssh_pass_host to avoid key mismatch
if [ -f /root/.ssh/known_hosts ]; then
  ssh-keygen -f /root/.ssh/known_hosts -R "linux_ssh_pass_host"
fi

# Ensure proper permissions for the .ssh directory and private key
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_rsa
chown root:root /root/.ssh/id_rsa

# Run the custom certificate installation if RUN_WITH_CERTIFICATE is true
if [ "${RUN_WITH_CERTIFICATE}" = "true" ]; then
  echo "RUN_WITH_CERTIFICATE is true. Installing custom certificate..."
  /usr/local/bin/install-cert.sh
else
  echo "RUN_WITH_CERTIFICATE is not set to true. Skipping certificate installation."
fi

ansible-galaxy install -r requirements.yml

# Run pre-playbook checks if the RUN_TESTS environment variable is set to true
if [ "${RUN_TESTS}" = "true" ]; then
  echo "RUN_TESTS is true. Running pre-playbook checks..."

  # Call the pre-playbook checks script
  /usr/local/bin/pre_playbook_checks.sh
fi

# Run the Ansible playbooks
if [ "${COMPOSE_PROFILES}" = "test" ]; then
  echo "'test' profile detected. Running Linux playbook only."
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

# Keep the container running (necessary for Docker to keep the container alive)
tail -f /dev/null
