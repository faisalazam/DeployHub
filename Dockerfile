FROM ubuntu:22.04

# Install Ansible and SSH client
RUN apt-get update && apt-get install -y     ansible     sshpass     python3-pip     openssh-client     && apt-get clean

# Set working directory
WORKDIR /ansible

# Copy Ansible files
COPY ansible /ansible

CMD ["tail", "-f", "/dev/null"]
