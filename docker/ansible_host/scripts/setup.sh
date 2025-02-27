#!/bin/sh

# Display environment info
python3 --version
pip show pywinrm
pip show molecule
molecule --version
pytest --version
ansible --version
ansible-playbook --version

echo "ENVIRONMENT=${ENVIRONMENT}"
echo "RESET_HOSTS_FILE=${RESET_HOSTS_FILE}"
echo "RUN_WITH_CERTIFICATE=${RUN_WITH_CERTIFICATE}"

# Ensure proper permissions for SSH
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_rsa
chown root:root /root/.ssh/id_rsa

if [ "${RESET_HOSTS_FILE}" = "true" ]; then
  # Path to known_hosts
  KNOWN_HOSTS_FILE="/root/.ssh/known_hosts"

  # Remove old entries for specified hosts to avoid connection issues.
  # For example, when the SSH server's host key changes (e.g., the server is rebuilt,
  # or the key is regenerated), the existing key in the known_hosts file becomes outdated.
  if [ -f "$KNOWN_HOSTS_FILE" ]; then
    ssh-keygen -f "$KNOWN_HOSTS_FILE" -R "linux_ssh_pass_host"
    ssh-keygen -f "$KNOWN_HOSTS_FILE" -R "linux_implicit_ssh_keys_host"
  fi

  # Adds the public key of the specified remote machines to the known_hosts file.
  # ssh-keyscan is used to gather the public keys of the specified remote machine (or server)
  # so that the supported keys get added to the known_hosts file.
  # Run `ls -lart /etc/ssh` in remote machine to see the public keys.
  ssh-keyscan -H linux_ssh_pass_host >> "$KNOWN_HOSTS_FILE"
  ssh-keyscan -H linux_implicit_ssh_keys_host >> "$KNOWN_HOSTS_FILE"

  # Configure linux_explicit_ssh_keys_host to use the externally generated keypair
  hostname="linux_explicit_ssh_keys_host"  # Replace with the actual hostname or IP
  key_file="/root/.ssh/linux_explicit_ssh_keys_host.pub"

  # Extract key type and value
  key_type=$(awk '{print $1}' "$key_file")
  key_value=$(awk '{print $2}' "$key_file")

  # Create a temporary file to hold the entry
  temp_file=$(mktemp)
  echo "$hostname $key_type $key_value" > "$temp_file"

  # Hash the temporary file
  ssh-keygen -H -f "$temp_file" 2>/dev/null
  cat "$temp_file" >> "$KNOWN_HOSTS_FILE"
  rm -f "$temp_file"
fi

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

