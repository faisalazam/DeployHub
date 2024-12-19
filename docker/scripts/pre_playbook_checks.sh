#!/bin/sh

# Run pre-playbook checks for best practices and syntax
if [ "${RUN_TESTS}" = "true" ]; then
  echo "RUN_TESTS is true. Running pre-playbook checks..."

  # Set environment variables for hosts
  ENVIRONMENT=${ENVIRONMENT:-"local"}

  # Define the path to the inventory
  INVENTORY_PATH="/ansible/inventory/${ENVIRONMENT}/hosts.yml"

  # Define the function to check connectivity
  check_connectivity() {
    # Check for Linux hosts
    echo "Checking connectivity to all Linux hosts..."
    ansible linux_hosts -i "${INVENTORY_PATH}" -m ping || { echo "Linux hosts ping failed"; exit 1; }

    # Check for Windows hosts
    echo "Checking connectivity to all Windows hosts..."
    ansible windows_hosts -i "${INVENTORY_PATH}" -m win_ping || { echo "Windows hosts ping failed"; exit 1; }
  }

  # Run the connectivity check
  check_connectivity

  if [ $? -ne 0 ]; then
    echo "Connectivity test failed. Exiting..."
    exit 1
  fi

  # Run ansible-lint to ensure playbooks meet best practices
  echo "Running ansible-lint..."
  ansible-lint /ansible/playbooks/*.yml
  if [ $? -ne 0 ]; then
    echo "ansible-lint failed. Exiting..."
    exit 1
  fi

  # Run ansible-playbook syntax check
  echo "Running ansible-playbook --syntax-check..."
  ansible-playbook --syntax-check -i /ansible/inventory/"${ENVIRONMENT}"/hosts.yml /ansible/playbooks/*.yml
  if [ $? -ne 0 ]; then
    echo "ansible-playbook syntax check failed. Exiting..."
    exit 1
  fi

  # Run pytest tests for any additional pre-playbook validations
  echo "Running pytest tests..."
  pytest /ansible/tests/test_pre_playbook.py --tb=short --disable-warnings
  if [ $? -ne 0 ]; then
    echo "Pre-playbook pytest tests failed. Exiting..."
    exit 1
  fi
fi
