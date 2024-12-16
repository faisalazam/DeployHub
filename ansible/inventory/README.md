To connect to the vm with http via host on forwarded port 55985 and regardless of whether the  `network_mode` set to
`host` or not.

Note the use of `host.docker.internal`, it's a way to access host from within the container.

Once https enabled, you can still connect with the below setting, but you have to run the following command
from the host machine first:

`winrs -r:http://localhost:55985 -u:'ansible-agent' -p:'ANS1BLE_P@sS!' powershell -Command Set-Item -Path 'WSMan:\localhost\Service\AllowUnencrypted' -Value $true`

```yaml
all:
  hosts:
    local_windows:
      ansible_port: 55985
      ansible_host: host.docker.internal # Just a way to access host from within the container
      ansible_connection: winrm
      ansible_winrm_scheme: http
      ansible_user: ansible-agent
      ansible_password: ANS1BLE_P@sS!
      ansible_winrm_transport: basic
```

To connect to the vm with https via host on forwarded port 55986 and regardless of whether the  `network_mode` set to
`host` or not.

```yaml
all:
  hosts:
    local_windows:
      ansible_port: 55986
      ansible_host: host.docker.internal # Just a way to access host from within the container
      ansible_connection: winrm
      ansible_winrm_scheme: https
      ansible_user: ansible-agent
      ansible_password: ANS1BLE_P@sS!
      ansible_winrm_transport: basic
      ansible_winrm_server_cert_validation: ignore
```

Host Gateway on Bridge:
Using host-gateway in extra_hosts is the most reliable and modern solution for accessing the host when using the Docker
bridge network. This avoids needing network_mode: host, which is less flexible and doesn't work well when multiple
containers are in use.

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway" # or - "local_windows_vm:host-gateway"
```