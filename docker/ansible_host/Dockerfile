# Use official Ubuntu 24.04 as the base image
# docker build -f ./Dockerfile -t ansible-automation ../..
FROM ubuntu:24.04

# Set environment variable to prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Define versions for dependencies
ENV PYTHON_VERSION=3.12
ENV PYTHON_PIP_VERSION=24.3.1

RUN apt-get update && apt-get install -y --no-install-recommends \
    sshpass \
    openssh-client \
    git \
    tzdata \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-venv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a virtual environment
RUN python${PYTHON_VERSION} -m venv /opt/venv

# Upgrade pip and install Ansible and required tools
COPY docker/ansible_host/requirements.txt /opt/requirements.txt
RUN /opt/venv/bin/python -m pip install --upgrade pip==${PYTHON_PIP_VERSION} && \
    /opt/venv/bin/pip install --no-cache-dir -r /opt/requirements.txt

# Verify the installed Ansible version
RUN /opt/venv/bin/ansible --version

# Reset DEBIAN_FRONTEND to its default
ENV DEBIAN_FRONTEND=

# Set the working directory
WORKDIR /ansible

COPY docker/ansible_host/scripts/install_cert.sh /usr/local/bin/install_cert.sh

# Make sure the script are executable
RUN chmod +x /usr/local/bin/install_cert.sh

# Set the default command to keep the container running
CMD [ \
    "/bin/sh", "-c", \
    ". /opt/venv/bin/activate && \
    python3 --version && \
    pip show pywinrm && \
    pip show molecule && \
    molecule --version && \
    pytest --version && \
    ansible --version && \
    ansible-playbook --version && \
    tail -f /dev/null" \
]
