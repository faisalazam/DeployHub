#!/bin/sh

# Run pre-playbook checks for best practices and syntax

ENVIRONMENT=${ENVIRONMENT:-"local"}
INVENTORY_PATH="/ansible/inventory/${ENVIRONMENT}/hosts.yml"

# Initialize a failure flag
FAILURE=0

# Define the function to check connectivity
check_connectivity() {
  echo "Checking connectivity to all Linux hosts..."
  ansible linux_hosts -i "${INVENTORY_PATH}" -m ping
  if [ $? -ne 0 ]; then
    echo "Linux hosts ping failed"
    FAILURE=1
  fi

  echo "Checking connectivity to all Windows hosts..."
  ansible windows_hosts -i "${INVENTORY_PATH}" -m win_ping
  if [ $? -ne 0 ]; then
    echo "Windows hosts ping failed"
    FAILURE=1
  fi
}

# Run the connectivity check
check_connectivity

# Run ansible-lint to ensure playbooks meet best practices
echo "Running ansible-lint..."
ansible-lint /ansible/playbooks/*.yml
if [ $? -ne 0 ]; then
  echo "ansible-lint failed."
  FAILURE=1
fi

# Run ansible-playbook syntax check
echo "Running ansible-playbook --syntax-check..."
ansible-playbook --syntax-check -i /ansible/inventory/"${ENVIRONMENT}"/hosts.yml /ansible/playbooks/*.yml
if [ $? -ne 0 ]; then
  echo "ansible-playbook syntax check failed."
  FAILURE=1
fi

# Run pytest tests for any additional pre-playbook validations
echo "Running pytest tests..."
pytest /ansible/tests/test_pre_playbook.py --tb=short --disable-warnings
if [ $? -ne 0 ]; then
  echo "Pre-playbook pytest tests failed."
  FAILURE=1
fi

# Final exit based on the failure flag
if [ $FAILURE -ne 0 ]; then
  echo "One or more pre-playbook checks failed. Exiting with errors."
  exit 1
else
  echo "All pre-playbook checks passed successfully."
  exit 0
fi
