

```shell
# NOTE: Run the DeployHub/scripts/generate_certificate.sh on the host first, to generate the certs

COMPOSE_PROFILES=test ENVIRONMENT=local docker-compose up -d
MSYS_NO_PATHCONV=1 docker exec -e RUN_WITH_CERTIFICATE=false -e ENVIRONMENT=local ansible sh /usr/local/bin/setup.sh
MSYS_NO_PATHCONV=1 docker exec -e RUN_TESTS=true -e ENVIRONMENT=local ansible sh /usr/local/bin/run_tests.sh
MSYS_NO_PATHCONV=1 docker exec -e COMPOSE_PROFILES=test -e ENVIRONMENT=local ansible sh /usr/local/bin/execute_playbooks.sh
MSYS_NO_PATHCONV=1 docker exec -e RUN_TESTS=true -e ENVIRONMENT=local ansible sh /usr/local/bin/post_playbook_checks.sh
````

## Given below are some sample and useful commands:

```shell
# It will ask for the passphrase of the private key once and cache it for the session.
# Good to avoid entering it again and again while running ansible commands.
eval $(ssh-agent)
ssh-add /root/.ssh/remote_servers_rsa_pri

ssh -i /root/.ssh/remote_servers_rsa_pri muhammad.faisal@192.168.181.20

# For checking CentOS version
cat /etc/os-release
cat /etc/centos-release

. /opt/venv/bin/activate

# host.hostname:"oau-tf-test-web1"

# For sudo password, add --ask-become-pass

ansible all -i 192.168.181.20, -m ping -u muhammad.faisal --private-key /root/.ssh/remote_servers_rsa_pri

ENVIRONMENT="test"

ANSIBLE_HOST_KEY_CHECKING=False ansible all -i /ansible/inventory/"${ENVIRONMENT}"/hosts.yml -m ping
ansible all -i /ansible/inventory/"${ENVIRONMENT}"/hosts.yml -m shell -a "hostname"
ansible all -i /ansible/inventory/"${ENVIRONMENT}"/hosts.yml -m shell -a "echo hello" -vvv
ansible all -i /ansible/inventory/"${ENVIRONMENT}"/hosts.yml -m command -a "whoami" --become -u root -vvv

# If you have a private key as .ppk file, you need to convert it to OpenSSH format before using it with Ansible.
ansible all -i 192.168.181.20, -m setup -u muhammad.faisal -e ansible_ssh_private_key_file=~/.ssh/remote_servers_rsa_pri -e 'ansible_python_interpreter=/usr/bin/python3'
ansible all -i 192.168.181.20, -m ping -u muhammad.faisal -e ansible_ssh_private_key_file=~/.ssh/remote_servers_rsa_pri -e 'ansible_python_interpreter=/usr/bin/python3'
ansible all -i /ansible/inventory/"${ENVIRONMENT}"/hosts.yml -m ping -u muhammad.faisal -e ansible_ssh_private_key_file=~/.ssh/remote_servers_rsa_pri -e 'ansible_python_interpreter=/usr/bin/python3'

ansible-vault encrypt /ansible/inventory/dev/group_vars/tomcat_windows_hosts/vault.yml --vault-password-file /ansible/vault_pass.txt
ansible-vault decrypt /ansible/inventory/dev/group_vars/tomcat_windows_hosts/vault.yml --vault-password-file /ansible/vault_pass.txt

ansible-vault encrypt /ansible/inventory/prod/group_vars/tomcat_windows_hosts/vault.yml --vault-password-file /ansible/vault_pass.txt
ansible-vault decrypt /ansible/inventory/prod/group_vars/tomcat_windows_hosts/vault.yml --vault-password-file /ansible/vault_pass.txt

ansible-vault encrypt /ansible/inventory/test/group_vars/metricbeat_hosts/vault.yml --vault-password-file /ansible/vault_pass.txt
ansible-vault decrypt /ansible/inventory/test/group_vars/metricbeat_hosts/vault.yml --vault-password-file /ansible/vault_pass.txt

ansible-vault encrypt /ansible/inventory/prod/group_vars/metricbeat_hosts/vault.yml --vault-password-file /ansible/vault_pass.txt
ansible-vault decrypt /ansible/inventory/prod/group_vars/metricbeat_hosts/vault.yml --vault-password-file /ansible/vault_pass.txt

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
    -i /ansible/inventory/"${ENVIRONMENT}"/metricbeat_hosts.yml \
    /ansible/playbooks/setup_metricbeat.yml \
    -e ENVIRONMENT="${ENVIRONMENT}" \
    --vault-password-file /ansible/vault_pass.txt
#    --ask-vault-pass

ansible-playbook \
    -i /ansible/inventory/"${ENVIRONMENT}"/hosts.yml \
    /ansible/playbooks/ping.yml \
    -e ENVIRONMENT="${ENVIRONMENT}" \
    --vault-password-file /ansible/vault_pass.txt
#    --ask-vault-pass

ansible-playbook \
    -i /ansible/inventory/"${ENVIRONMENT}"/hosts.yml \
    /ansible/playbooks/connectivity.yml \
    -e ENVIRONMENT="${ENVIRONMENT}" \
    --vault-password-file /ansible/vault_pass.txt
#    --ask-vault-pass


# Better to close other applications on the remote to avoid folder lock issues before running playbooks.
# File Explorer and Services (services.msc) frequently cause folder ("tomcat/srva") lock issue.
ansible-playbook \
    -i /ansible/inventory/"${ENVIRONMENT}"/tomcat_windows_hosts.yml \
    /ansible/playbooks/upgrade_tomcat_windows.yml \
    -e ENVIRONMENT="${ENVIRONMENT}" \
    -e upgrade_tomcat_upgrade_step="prepare" \
    -e upgrade_tomcat_zip_filename="apache-tomcat-9.0.98-windows-x64.zip" \
    --vault-password-file /ansible/vault_pass.txt
#    --ask-vault-pass


# Better to close other applications on the remote to avoid folder lock issues before running playbooks.
# File Explorer and Services (services.msc) frequently cause folder ("tomcat/srva") lock issue.
ansible-playbook \
    -i /ansible/inventory/"${ENVIRONMENT}"/tomcat_windows_hosts.yml \
    /ansible/playbooks/upgrade_tomcat_windows.yml \
    -e ENVIRONMENT="${ENVIRONMENT}" \
    -e upgrade_tomcat_upgrade_step="upgrade" \
    -e upgrade_tomcat_service_to_uninstall="" \
    -e upgrade_tomcat_current_service_to_upgrade="TOMCAT964_SRVA" \
    -e upgrade_tomcat_zip_filename="apache-tomcat-9.0.98-windows-x64.zip" \
    --vault-password-file /ansible/vault_pass.txt
#    --ask-vault-pass
```

If your remote machines are not compatible with the latest ansible and python versions,
you can try using the Dockerfile.old_ansible_and_python file.