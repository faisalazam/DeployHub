

To connect to the vm with http via host on forwarded port 55985 and with `network_mode` set to `host`.

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


To connect to the vm with https via host on forwarded port 55986 and with `network_mode` set to `host`.

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