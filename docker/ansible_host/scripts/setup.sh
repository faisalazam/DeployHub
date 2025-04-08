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

# Function to add a host key to known_hosts
add_ssh_key_to_known_hosts() {
  hostname="$1"  # Hostname or IP address
  key_file="$2"  # Path to the public key file
  known_hosts_file="$3"  # Path to the known_hosts file

  # Extract key type and value
  key_type=$(awk '{print $1}' "$key_file")
  key_value=$(awk '{print $2}' "$key_file")

  # Create a temporary file to hold the entry
  temp_file=$(mktemp)
  echo "$hostname $key_type $key_value" > "$temp_file"

  # Hash the temporary file
  ssh-keygen -H -f "$temp_file" 2>/dev/null
  cat "$temp_file" >> "$known_hosts_file"
  rm -f "$temp_file"
}

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

  # Configure the hosts to use the externally generated keypair
  add_ssh_key_to_known_hosts "linux_explicit_ssh_keys_host" "/root/.ssh/linux_explicit_ssh_keys_host.pub" "$KNOWN_HOSTS_FILE"
  add_ssh_key_to_known_hosts "oracle_linux_9_explicit_ssh_keys_host" "/root/.ssh/oracle_linux_9_explicit_ssh_keys_host.pub" "$KNOWN_HOSTS_FILE"
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

# 📦 Install required Ansible Galaxy collections only if not already installed
GALAXY_DIR="/ansible/.galaxy"
GALAXY_COLLECTIONS_DIR="${GALAXY_DIR}/collections"
if [ ! -d "${GALAXY_COLLECTIONS_DIR}" ] || [ -z "$(ls -A ${GALAXY_COLLECTIONS_DIR})" ]; then
  echo "📦 Installing Ansible Galaxy collections..."
  ansible-galaxy collection install -r /ansible/requirements.yml -p "${GALAXY_COLLECTIONS_DIR}" || { echo "❌ Failed to install Ansible Galaxy collections"; exit 1; }
else
  echo "✅ Ansible Galaxy collections already installed. Skipping."
fi

# 📦 Install required Ansible Galaxy roles only if not already installed
GALAXY_ROLES_DIR="${GALAXY_DIR}/roles"
if [ ! -d "${GALAXY_ROLES_DIR}" ] || [ -z "$(ls -A ${GALAXY_ROLES_DIR})" ]; then
  echo "📦 Installing Ansible Galaxy roles..."
  ansible-galaxy install -r /ansible/requirements.yml -p "${GALAXY_ROLES_DIR}" || { echo "❌ Failed to install Ansible Galaxy roles"; exit 1; }
else
  echo "✅ Ansible Galaxy roles already installed. Skipping."
fi

echo "🎉 Setup complete!"
