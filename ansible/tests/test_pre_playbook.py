import pytest
import subprocess
import re
import socket

# Function to remove ANSI escape codes
def remove_ansi_escape_codes(text):
    return re.sub(r'\x1b\[[0-9;]*m', '', text)

# Helper function for checking version
def check_version(command, expected_versions, version_extractor=None, ignore_patch=False):
    """
    Generic function to check version of a command-line tool.
    If ignore_patch=True, only major.minor will be checked.
    """
    try:
        result = subprocess.check_output(command, stderr=subprocess.STDOUT).decode().strip()
        if version_extractor:
            result = version_extractor(result)

        # Remove ANSI codes
        clean_result = remove_ansi_escape_codes(result)

        # ignore_patch means if the version is 3.10.16, then only the major.minor (i.e. 3.10) will be checked
        # whereas the patch part (i.e. .16) will be ignored.
        if ignore_patch:
            # If expected_versions is a list, check if any of the expected versions match
            if isinstance(expected_versions, list):
                if not any(re.search(rf"{re.escape(ver)}\.\d+", clean_result) for ver in expected_versions):
                    pytest.fail(f"Expected one of the versions {expected_versions}.x, but got {clean_result}")
            else:
                if not re.search(rf"{re.escape(expected_versions)}\.\d+", clean_result):
                    pytest.fail(f"Expected version {expected_versions}.x, but got {clean_result}")
        else:
            # If expected_versions is a list, check if any of the expected versions match
            if isinstance(expected_versions, list):
                if not any(ver in clean_result for ver in expected_versions):
                    pytest.fail(f"Expected one of the versions {expected_versions}, but got {clean_result}")
            else:
                if expected_versions not in clean_result:
                    pytest.fail(f"Expected version {expected_versions}, but got {clean_result}")

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
    expected_versions = ["core 2.16.14", "core 2.18.3"]
    check_version(["ansible", "--version"], expected_versions)

# Test for checking Python version
def test_python_version():
    # Find in chatgpt: commit msg why we changed to find from stat
    expected_versions = ["3.10", "3.12"]
    check_version(["python3", "--version"], expected_versions, extract_version, ignore_patch=True)

# Test for checking pip version
def test_pip_version():
    expected_version = "25.0.1"
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
    expected_version = "25.2.1"
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
