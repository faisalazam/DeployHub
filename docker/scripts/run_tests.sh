#!/bin/sh

# Run tests if the RUN_TESTS variable is true
if [ "${RUN_TESTS}" = "true" ]; then
  echo "Running pre-playbook checks..."
  sh /usr/local/bin/pre_playbook_checks.sh
else
  echo "RUN_TESTS is not set to true. Skipping tests."
fi
