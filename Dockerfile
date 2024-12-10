# Use official Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Install necessary dependencies and tools
RUN apt-get update && apt-get install -y \
    ansible \
    sshpass \
    python3-pip \
    openssh-client \
    && apt-get clean

# Install the latest version of pywinrm
RUN pip3 install --no-cache-dir pywinrm

# Set the working directory
WORKDIR /ansible

# Copy Ansible playbooks and other necessary files into the container
COPY ansible /ansible

# Set the default command to keep the container running
CMD ["tail", "-f", "/dev/null"]
