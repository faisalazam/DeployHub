#!/bin/sh

# If you face script not found error even though the script does exist, then it'll more likely be due to the fact that
# the script has CRLF line terminators (Windows-style). Run the following command to convert CRLF to LF to fix it:
# dos2unix scripts/initialize_ssh_keys.sh
# You can run the following to check the line terminators:
# file scripts/initialize_ssh_keys.sh
# If the output contains something like below, then it'd mean that it needs fixing to run on unix systems:
# ASCII text executable, with CRLF line terminators

ROOT_USER="root"
SSH_DIR="/etc/ssh"
AUTHORIZED_KEYS="/root/.ssh/authorized_keys"
SSH_HOST_RSA_KEY="$SSH_DIR/ssh_host_rsa_key"
SSHD_PATH="/usr/sbin/sshd"

# Copy the public key to the authorized_keys file explicitly if you're not mounting it through docker compose...
#cp .ssh/id_rsa.pub /root/.ssh/authorized_keys

echo "Setting up SSH directory and permissions..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown "$ROOT_USER:$ROOT_USER" "$SSH_DIR"

# Check and set permissions for the SSH host key
if [ -f "$SSH_HOST_RSA_KEY" ]; then
  chmod 600 "$SSH_HOST_RSA_KEY"
  chown "$ROOT_USER:$ROOT_USER" "$SSH_HOST_RSA_KEY"
else
  echo "ERROR: $SSH_HOST_RSA_KEY not found."
  exit 1
fi

if [ -f "$AUTHORIZED_KEYS" ]; then
  chown "$ROOT_USER:$ROOT_USER" "$AUTHORIZED_KEYS"
  chmod 600 "$AUTHORIZED_KEYS"
else
  echo "ERROR: $AUTHORIZED_KEYS not found."
  exit 1
fi

echo "Starting SSH server..."
exec "$SSHD_PATH" -D
