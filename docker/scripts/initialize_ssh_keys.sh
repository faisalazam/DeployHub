#!/bin/sh

# If you face script not found error even though the script does exist, then it'll more likely be due to the fact that
# the script has CRLF line terminators (Windows-style). Run the following command to convert CRLF to LF to fix it:
# dos2unix scripts/initialize_ssh_keys.sh
# You can run the following to check the line terminators:
# file scripts/initialize_ssh_keys.sh
# If the output contains something like below, then it'd mean that it needs fixing to run on unix systems:
# ASCII text executable, with CRLF line terminators

ROOT_USER="root"
SSH_DIR="/root/.ssh"
AUTHORIZED_KEYS="${SSH_DIR}/authorized_keys"
SSHD_PATH="/usr/sbin/sshd"

# Copy the public key to the authorized_keys file explicitly if you're not mounting it through docker-compose...
#cp .ssh/id_rsa.pub /root/.ssh/authorized_keys

echo "Setting up SSH directory and permissions..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown "$ROOT_USER:$ROOT_USER" "$SSH_DIR"

if [ -f "$AUTHORIZED_KEYS" ]; then
  chmod 600 "$AUTHORIZED_KEYS"
else
  echo "Warning: $AUTHORIZED_KEYS not found."
fi

echo "Starting SSH server..."
exec "$SSHD_PATH" -D
