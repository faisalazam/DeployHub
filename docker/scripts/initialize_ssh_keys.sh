#!/bin/sh

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
