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
fi
