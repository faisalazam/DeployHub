

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

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
    -i /ansible/inventory/"${ENVIRONMENT}"/hosts.yml \
    /ansible/playbooks/setup_metricbeat.yml \
    -e ENVIRONMENT="${ENVIRONMENT}"
```

If your remote machines are not compatible with the latest ansible and python versions,
you can try using the Dockerfile.old_ansible_and_python file.