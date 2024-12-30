#!/bin/sh

# Activate the virtual environment to ensures that the ansible, ansible-lint, and pytest commands are available
. /opt/venv/bin/activate

# Environment variables
ENVIRONMENT=${ENVIRONMENT:-"local"}
COMPOSE_PROFILES=${COMPOSE_PROFILES:-"default"}
INVENTORY_PATH="/ansible/inventory/${ENVIRONMENT}/hosts.yml"

# Initialize failure flag
FAILURE=0

# Log function for consistency
log() {
    echo "[INFO] $1"
}

# Error function to set the failure flag
error() {
    echo "[ERROR] $1"
    FAILURE=1
}

# Check connectivity
check_connectivity() {
    log "Checking connectivity to all Linux hosts..."
    ansible linux_hosts -i "${INVENTORY_PATH}" -m ping || error "Linux hosts ping failed."

    if [ "${COMPOSE_PROFILES}" != "test" ]; then
        log "Checking connectivity to all Windows hosts..."
        ansible windows_hosts -i "${INVENTORY_PATH}" -m win_ping || error "Windows hosts ping failed."
    fi
}

# Run ansible-lint
run_ansible_lint() {
    log "Running ansible-lint..."
    ansible-lint /ansible/playbooks/*.yml || error "ansible-lint failed."
}

# Run ansible-playbook syntax check
run_syntax_check() {
    log "Running ansible-playbook --syntax-check..."
    ansible-playbook --syntax-check -i "${INVENTORY_PATH}" /ansible/playbooks/*.yml || error "ansible-playbook syntax check failed."
}

# Run pytest
run_pytest() {
    log "Running pytest tests..."
    pytest /ansible/tests/test_pre_playbook.py --tb=short --disable-warnings || error "Pre-playbook pytest tests failed."
}

# Perform all checks
log "Starting pre-playbook checks..."
check_connectivity
run_ansible_lint
run_syntax_check
run_pytest

# Final exit based on failure flag
if [ $FAILURE -ne 0 ]; then
    log "One or more pre-playbook checks failed. Exiting with errors."
    exit 1
else
    log "All pre-playbook checks passed successfully."
    exit 0
fi
