# Use oraclelinux:9 as the base image
# docker build -f ./Dockerfile -t oracle_linux_9_ssh_keys_host .
FROM oraclelinux:9

# Install SSH server and required dependencies
RUN dnf -y install openssh-server && \
    dnf clean all && \
    mkdir -p /var/run/sshd /root/.ssh

# Configure SSH server for key-based login
RUN sed -i \
    -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' \
    -e 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' \
    -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' \
    -e 's/^#AuthorizedKeysFile/AuthorizedKeysFile/' \
    /etc/ssh/sshd_config

# Expose SSH port
EXPOSE 22

# Set a default command to Start SSHD
CMD ["/usr/sbin/sshd", "-D"]