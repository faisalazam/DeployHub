# Use official Ubuntu 22.04 as the base image
# docker build -f ./Dockerfile -t ansible-automation ..
FROM ubuntu:22.04

# Set environment variable to prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies and tools
RUN apt-get update && apt-get install -y \
    ansible \
    sshpass \
    python3-pip \
    openssh-client \
    git \
    tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install the latest version of pywinrm
RUN pip3 install --no-cache-dir pywinrm

# Reset DEBIAN_FRONTEND to its default
ENV DEBIAN_FRONTEND=

# Set the working directory
WORKDIR /ansible

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s CMD ansible --version || exit 1

# Set the default command to keep the container running
CMD ["sh", "-c", "ansible-playbook --version && tail -f /dev/null"]

