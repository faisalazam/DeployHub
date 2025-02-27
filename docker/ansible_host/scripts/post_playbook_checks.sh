#!/bin/sh

# Navigate to the tests directory
cd ../ansible/tests || {
    echo "Failed to change directory to tests folder."
    exit 1
}

# Run all tests, allowing all to run even if there are failures
pytest *.py --disable-warnings --maxfail=0
pytest_exit_code=$?

# Check if pytest found any failures
if [ $pytest_exit_code -ne 0 ]; then
    echo "Post-playbook tests completed with failures."
    exit $pytest_exit_code
else
    echo "All post-playbook tests passed successfully."
    exit 0
fi
