import pytest
import socket
import subprocess
import re

# Function to remove ANSI escape codes
def remove_ansi_escape_codes(text):
    return re.sub(r'\x1b\[[0-9;]*m', '', text)

# Test for checking ansible version
def test_ansible_version():
    expected_version = "core 2.18.1"
    try:
        result = subprocess.check_output(
            ["ansible", "--version"],
            stderr=subprocess.STDOUT
        ).decode().strip()
        if expected_version not in result:
            pytest.fail(f"Expected ansible version {expected_version}, but got {result}")
    except subprocess.CalledProcessError as e:
        pytest.fail(f"Failed to check ansible version: {e.output.decode()}")

# Test for checking Python version
def test_python_version():
    expected_version = "3.12.3"
    try:
        result = subprocess.check_output(
            ["python3", "--version"],
            stderr=subprocess.STDOUT
        ).decode().strip()
        # Check if the output contains the expected Python version
        if expected_version not in result:
            pytest.fail(f"Expected Python version {expected_version}, but got {result}")
    except subprocess.CalledProcessError as e:
        pytest.fail(f"Failed to check Python version: {e.output.decode()}")

def test_pip_version():
    expected_version = "24.3.1"
    pip_version = subprocess.check_output(["/opt/venv/bin/pip", "--version"]).decode("utf-8")
    installed_version = pip_version.split()[1]
    assert installed_version == expected_version, f"Expected pip version {expected_version}, but got {installed_version}"

# Test for checking pywinrm version
def test_pywinrm_version():
    expected_version = "0.5.0"
    try:
        result = subprocess.check_output(
            ["python3", "-c", "import winrm; print(winrm.__version__)"],
            stderr=subprocess.STDOUT
        ).decode().strip()
        assert result == expected_version, f"Expected pywinrm version {expected_version}, but got {result}"
    except subprocess.CalledProcessError as e:
        pytest.fail(f"Failed to check pywinrm version: {e.output.decode()}")

# Test for checking molecule version
def test_molecule_version():
    expected_version = "24.12.0"
    try:
        result = subprocess.check_output(
            ["molecule", "--version"],
            stderr=subprocess.STDOUT
        ).decode().strip()
        assert expected_version in result, f"Expected molecule version {expected_version}, but got {result}"
    except subprocess.CalledProcessError as e:
        pytest.fail(f"Failed to check molecule version: {e.output.decode()}")

# Test for checking ansible-lint version
def test_ansible_lint_version():
    expected_version = "24.12.2"
    try:
        result = subprocess.check_output(
            ["ansible-lint", "--version"],
            stderr=subprocess.STDOUT
        ).decode().strip()
        clean_result = remove_ansi_escape_codes(result)
        version = clean_result.split()[1]
        assert version == expected_version, f"Expected ansible-lint version {expected_version}, but got {version}"
    except subprocess.CalledProcessError as e:
        pytest.fail(f"Failed to check ansible-lint version: {e.output.decode()}")

# Test for checking pytest version
def test_pytest_version():
    expected_version = "8.3.4"
    try:
        result = subprocess.check_output(
            ["pytest", "--version"],
            stderr=subprocess.STDOUT
        ).decode().strip()
        version = result.split()[1]
        assert version == expected_version, f"Expected pytest version {expected_version}, but got {version}"
    except subprocess.CalledProcessError as e:
        pytest.fail(f"Failed to check pytest version: {e.output.decode()}")

# Test for checking pytest-testinfra version
def test_pytest_testinfra_version():
    expected_version = "10.1.1"
    try:
        result = subprocess.check_output(
            ["pip", "show", "pytest-testinfra"],
            stderr=subprocess.STDOUT
        ).decode().strip()
        if expected_version not in result:
            pytest.fail(f"Expected pytest-testinfra version {expected_version}, but got {result}")
    except subprocess.CalledProcessError as e:
        pytest.fail(f"Failed to check pytest-testinfra version: {e.output.decode()}")
    except FileNotFoundError:
        pytest.fail("pytest-testinfra is not installed. Please install it using 'pip install pytest-testinfra'.")

# Example check for network connectivity
def test_network_connectivity():
    critical_endpoints = ['google.com', 'github.com']
    for endpoint in critical_endpoints:
        try:
            socket.create_connection((endpoint, 80), timeout=5)
        except OSError:
            pytest.fail(f"Network connectivity to {endpoint} failed.")
