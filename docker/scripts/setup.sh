#!/bin/sh

# Activate the virtual environment
. /opt/venv/bin/activate

# Display environment info
python3 --version
pip show pywinrm
pip show molecule
molecule --version
pytest --version
ansible --version
ansible-playbook --version

echo "ENVIRONMENT=${ENVIRONMENT}"
echo "RUN_WITH_CERTIFICATE=${RUN_WITH_CERTIFICATE}"

# Ensure proper permissions for SSH
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_rsa
chown root:root /root/.ssh/id_rsa

# Remove known_hosts entry
if [ -f /root/.ssh/known_hosts ]; then
  ssh-keygen -f /root/.ssh/known_hosts -R "linux_ssh_pass_host"
fi

# Install custom certificate if needed
if [ "${RUN_WITH_CERTIFICATE}" = "true" ]; then
  echo "Installing custom certificate..."
  /usr/local/bin/install-cert.sh
else
  echo "Skipping certificate installation."
fi

# Install required Ansible Galaxy roles
ansible-galaxy install -r requirements.yml || { echo "Failed to install Ansible Galaxy roles"; exit 1; }

