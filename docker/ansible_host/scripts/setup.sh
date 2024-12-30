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

# Path to known_hosts
KNOWN_HOSTS_FILE="/root/.ssh/known_hosts"

# Remove old entry for linux_ssh_pass_host
if [ -f "$KNOWN_HOSTS_FILE" ]; then
  ssh-keygen -f "$KNOWN_HOSTS_FILE" -R "linux_ssh_pass_host"
fi

# Add the current host key for linux_ssh_pass_host
ssh-keyscan -H linux_ssh_pass_host >> "$KNOWN_HOSTS_FILE"

# Install custom certificate if needed
if [ "${RUN_WITH_CERTIFICATE}" = "true" ]; then
  echo "Installing custom certificate..."
  /usr/local/bin/install_cert.sh
else
  echo "Skipping certificate installation."
fi

# Set correct ownership
chown -R root:root /ansible

# Set directories to 755 (read, write, execute for owner, read/execute for others)
find /ansible -type d -exec chmod 755 {} \;

# Set files to 644 (read, write for owner, read for others)
find /ansible -type f -exec chmod 644 {} \;

# Install required Ansible Galaxy roles
ansible-galaxy install -r requirements.yml || { echo "Failed to install Ansible Galaxy roles"; exit 1; }

