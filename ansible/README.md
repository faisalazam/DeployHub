Static role-specific values → roles/metricbeat/vars/main.yml
Environment-specific values → inventory/{env}/group_vars/linux_hosts.yml
Sensitive values → vars/secrets.yml (encrypted)
Default values (if needed) → vars/default_vars.yml

Ansible will prompt you to enter a password before opening the file in an editor. Once you save and exit, it
automatically encrypts the file with that password.

```shell
ansible-vault create /ansible/inventory/dev/group_vars/tomcat_windows_hosts/vault.yml
```

If vault.yml already exists, instead of create, you should encrypt it manually using:

```shell
ansible-vault encrypt /ansible/inventory/dev/group_vars/tomcat_windows_hosts/vault.yml
ansible-vault decrypt /ansible/inventory/dev/group_vars/tomcat_windows_hosts/vault.yml
```

To modify it later, use:

```shell
ansible-vault edit /ansible/inventory/dev/group_vars/tomcat_windows_hosts/vault.yml
```

For the password, get the value of, e.g. `ansible_vault_password` from wherever it is stored, such as BitWarden.
