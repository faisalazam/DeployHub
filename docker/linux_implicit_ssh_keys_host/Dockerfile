# Use Ubuntu 24.04 as the base image
# docker build -f ./Dockerfile -t linux_ssh_keys_host .
FROM ubuntu:24.04

# Install SSH server and required dependencies
RUN apt-get update && \
    apt-get install -y openssh-server && \
    mkdir -p /var/run/sshd && \
    mkdir -p /root/.ssh && \
    # Clean up apt cache
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure SSH server for key-based login
RUN sed -i \
    -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' \
    -e 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' \
    -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' \
    -e 's/^#AuthorizedKeysFile/AuthorizedKeysFile/' \
    /etc/ssh/sshd_config

# Expose SSH port
EXPOSE 22

# Set a default command to show the SSH daemon status
CMD ["sh", "-c", "sshd -v && tail -f /dev/null"]