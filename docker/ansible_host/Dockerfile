# Use official Ubuntu 24.04 as the base image
# docker build -f ./Dockerfile -t ansible-automation ../..
FROM ubuntu:24.04

# Set environment variable to prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Define versions for dependencies
# Python 3.10 is compatible with Python versions like 2.7.x, 3.6.x, 3.9.x etc. on remote machines.
ARG PYTHON_VERSION=3.10
ENV PYTHON_PIP_VERSION=25.0.1

RUN apt-get update && \
    if [ "$PYTHON_VERSION" = "3.10" ]; then \
        apt-get install -y --no-install-recommends software-properties-common && \
        add-apt-repository ppa:deadsnakes/ppa && \
        apt-get update; \
    fi && \
    apt-get install -y --no-install-recommends \
        sshpass \
        openssh-client \
        git \
        tzdata \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-venv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set timezone
RUN ln -fs /usr/share/zoneinfo/Australia/Sydney /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Create a virtual environment
RUN python${PYTHON_VERSION} -m venv /opt/venv

# Ensure the virtual environment is automatically used in all shell sessions
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip and install Ansible and required tools
COPY docker/ansible_host/python${PYTHON_VERSION}_requirements.txt /opt/python${PYTHON_VERSION}_requirements.txt
RUN python -m pip install --upgrade pip==${PYTHON_PIP_VERSION} && \
    pip install --no-cache-dir -r /opt/python${PYTHON_VERSION}_requirements.txt

# Verify the installed Ansible version
RUN ansible --version

# Reset DEBIAN_FRONTEND to its default
ENV DEBIAN_FRONTEND=

# Set the working directory
WORKDIR /ansible

COPY docker/ansible_host/scripts/install_cert.sh /usr/local/bin/install_cert.sh

# Make sure the script is executable
RUN chmod +x /usr/local/bin/install_cert.sh

# Set the default command to keep the container running
CMD [ \
    "/bin/sh", "-c", \
    "python3 --version && \
    pip --version && \
    pip show pywinrm && \
    pip show molecule && \
    molecule --version && \
    pytest --version && \
    ansible --version && \
    ansible-playbook --version && \
    tail -f /dev/null" \
]
