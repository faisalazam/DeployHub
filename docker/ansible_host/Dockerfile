# Use official Ubuntu 24.04 as the base image
# docker build -f ./Dockerfile -t ansible-automation ../..
FROM ubuntu:24.04

# Set environment variable to prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Define versions for dependencies
ENV ANSIBLE_VERSION=11.0
ENV ANSIBLE_CORE_VERSION=2.18.1
ENV PYTHON_VERSION=3.12
ENV PYTHON_PIP_VERSION=24.3.1
ENV PYWINRM_VERSION=0.5.0
ENV MOLECULE_VERSION=24.12.0
ENV ANSIBLE_LINT_VERSION=v25.1.2
ENV PYTEST_VERSION=8.3.4
ENV PYTEST_TESTINFRA_VERSION=10.1.1

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
RUN /opt/venv/bin/python -m pip install --upgrade pip==${PYTHON_PIP_VERSION} && \
    /opt/venv/bin/pip install ansible==${ANSIBLE_VERSION} "ansible-core==${ANSIBLE_CORE_VERSION}" \
    pywinrm==${PYWINRM_VERSION} \
    "molecule[docker]"==${MOLECULE_VERSION} \
    ansible-lint==${ANSIBLE_LINT_VERSION} \
    pytest==${PYTEST_VERSION} \
    pytest-testinfra==${PYTEST_TESTINFRA_VERSION}

# Verify the installed Ansible version
RUN /opt/venv/bin/ansible --version

# Reset DEBIAN_FRONTEND to its default
ENV DEBIAN_FRONTEND=

# Set the working directory
WORKDIR /ansible

COPY docker/ansible_host/scripts/install_cert.sh /usr/local/bin/install_cert.sh

# Make sure the script are executable
RUN chmod +x /usr/local/bin/install_cert.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s CMD ansible --version || exit 1

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
