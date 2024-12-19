import pytest
import socket

# Example check
def test_network_connectivity():
    critical_endpoints = ['google.com', 'github.com']
    for endpoint in critical_endpoints:
        try:
            socket.create_connection((endpoint, 80), timeout=5)
        except OSError:
            pytest.fail(f"Network connectivity to {endpoint} failed.")