import pytest
import subprocess
import re
import socket

# Function to remove ANSI escape codes
def remove_ansi_escape_codes(text):
    return re.sub(r'\x1b\[[0-9;]*m', '', text)

# Helper function for checking version
def check_version(command, expected_version, version_extractor=None):
    """
    Generic function to check version of a command-line tool.
    """
    try:
        result = subprocess.check_output(command, stderr=subprocess.STDOUT).decode().strip()
        if version_extractor:
            result = version_extractor(result)
        if expected_version not in result:
            pytest.fail(f"Expected version {expected_version}, but got {result}")
    except subprocess.CalledProcessError as e:
        pytest.fail(f"Failed to check version for command '{' '.join(command)}': {e.output.decode()}")

# Version extractors for specific tools
def extract_version(result):
    return result.split()[1]

def extract_pywinrm_version(result):
    return result.strip()

def extract_ansible_lint_version(result):
    clean_result = remove_ansi_escape_codes(result)
    return clean_result.split()[1]

# Test for checking ansible version
def test_ansible_version():
    expected_version = "core 2.18.1"
    check_version(["ansible", "--version"], expected_version)

# Test for checking Python version
def test_python_version():
    expected_version = "3.12.3"
    check_version(["python3", "--version"], expected_version, extract_version)

# Test for checking pip version
def test_pip_version():
    expected_version = "24.3.1"
    check_version(["/opt/venv/bin/pip", "--version"], expected_version, extract_version)

# Test for checking pywinrm version
def test_pywinrm_version():
    expected_version = "0.5.0"
    check_version(["python3", "-c", "import winrm; print(winrm.__version__)"], expected_version, extract_pywinrm_version)

# Test for checking molecule version
def test_molecule_version():
    expected_version = "24.12.0"
    check_version(["molecule", "--version"], expected_version, extract_version)

# Test for checking ansible-lint version
def test_ansible_lint_version():
    expected_version = "25.1.2"
    check_version(["ansible-lint", "--version"], expected_version, extract_ansible_lint_version)

# Test for checking pytest version
def test_pytest_version():
    expected_version = "8.3.4"
    check_version(["pytest", "--version"], expected_version, extract_version)

# Test for checking pytest-testinfra version
def test_pytest_testinfra_version():
    expected_version = "10.1.1"
    check_version(["pip", "show", "pytest-testinfra"], expected_version)

# Example check for network connectivity
def test_network_connectivity():
    critical_endpoints = ['google.com', 'github.com']
    for endpoint in critical_endpoints:
        try:
            socket.create_connection((endpoint, 80), timeout=5)
        except OSError:
            pytest.fail(f"Network connectivity to {endpoint} failed.")
