import pytest
import subprocess
import yaml
from pathlib import Path
import time

@pytest.fixture(scope="module")
def playbook_vars():
    """
    Load the playbook variables from the YAML file.
    """
    playbook_path = Path(f"/ansible/playbooks/deploy_linux.yml")

    if not playbook_path.exists():
        pytest.fail(f"Playbook file {playbook_path} does not exist.")

    with playbook_path.open() as file:
        playbook = yaml.safe_load(file)

    # Extract variables (e.g., from tasks or defaults)
    vars_dict = {}
    for task in playbook[0].get('tasks', []):
        vars_dict.update(task.get('vars', {}))

    return vars_dict

@pytest.fixture
def ansible_inventory(ansible_inventory):
    """
    Ensure the inventory has a host group named 'linux_hosts' for the playbook.
    """
    assert "linux_hosts" in ansible_inventory.groups, "Inventory missing 'linux_hosts' group."
    return ansible_inventory

@pytest.fixture(scope="module")
def ansible_playbook():
    """
    Fixture to run an Ansible playbook.
    """
    def _run_playbook(playbook_path, inventory_path=None, extra_vars=None):
        extra_vars = extra_vars or {}

        inventory_path = inventory_path or "/ansible/inventory/local/hosts.yml"

        # Construct the ansible-playbook command
        cmd = [
            "ansible-playbook",
            "-i", inventory_path,  # Use the passed inventory or the default
            playbook_path,
        ]

        # Add extra variables to the command
        for key, value in extra_vars.items():
            cmd.append(f"-e {key}={value}")

        # Run the ansible-playbook command
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            pytest.fail(f"Playbook failed: {result.stderr}")

        return result

    return _run_playbook

def test_playbook_run(ansible_playbook):
    """
    Test that the playbook runs successfully with the specified environment.
    """
    environment = "local"
    playbook_path = "/ansible/playbooks/deploy_linux.yml"
    inventory_path = f"/ansible/inventory/{environment}/hosts.yml"
    extra_vars = {"ENVIRONMENT": environment}

    result = ansible_playbook(playbook_path, inventory_path=inventory_path, extra_vars=extra_vars)

    assert result.returncode == 0, f"Playbook failed with return code {result.returncode}"
