# Vagrant and VirtualBox Command Categories

---

## **Vagrant Core Commands**

| **Command**          | **Description**                                                                               |
|----------------------|-----------------------------------------------------------------------------------------------|
| `vagrant up`         | Starts the Vagrant environment by creating and configuring a VM.                              |
| `vagrant up --debug` | Starts the VM with detailed debugging output.                                                 |
| `vagrant reload`     | Restarts the VM, applying any changes in the `Vagrantfile`.                                   |
| `vagrant port`       | Lists all forwarded ports for the VM.                                                         |
| `vagrant provision`  | Runs the provisioning scripts defined in the `Vagrantfile`.                                   |
| `vagrant halt`       | Gracefully shuts down the VM.                                                                 |
| `vagrant destroy -f` | Forces the removal of the VM and its associated resources without prompting for confirmation. |
| `vagrant status`     | Shows the status of the Vagrant environment (e.g., running, stopped).                         |

---

## **Vagrant Miscellaneous Commands**

| **Command**              | **Description**                                                                                |
|--------------------------|------------------------------------------------------------------------------------------------|
| `vagrant winrm`          | Opens a remote shell to the Windows VM using WinRM.                                            |
| `vagrant winrm -c "..."` | Executes the specified command in the VM using WinRM. Example: `echo 'WinRM Test Successful'`. |

---

## **VirtualBox Commands**

| **Command**                                       | **Description**                                                  |
|---------------------------------------------------|------------------------------------------------------------------|
| `vboxmanage list vms`                             | Lists all VMs registered in VirtualBox.                          |
| `VBoxManage list runningvms`                      | Lists all currently running VMs in VirtualBox.                   |
| `vboxmanage controlvm <VM_NAME> poweroff`         | Powers off the specified VM.                                     |
| `vboxmanage controlvm WINDOWS_SERVER poweroff`    | Powers off the "WINDOWS_SERVER" VM.                              |
| `vboxmanage unregistervm <VM_NAME> --delete`      | Unregisters and deletes the specified VM from VirtualBox.        |
| `vboxmanage unregistervm WINDOWS_SERVER --delete` | Unregisters and deletes the "WINDOWS_SERVER" VM from VirtualBox. |
| `VBoxManage showvminfo <VM_NAME> --details`       | Displays detailed information about the specified VM.            |
| `VBoxManage showvminfo WINDOWS_SERVER --details`  | Displays detailed information about the "WINDOWS_SERVER" VM.     |

---

## **VirtualBox NAT Port Forwarding**

| **Command**                                                | **Description**                                                         |
|------------------------------------------------------------|-------------------------------------------------------------------------|
| `VBoxManage controlvm <VM_NAME> natpf1 list`               | Lists all NAT port forwarding rules for the specified VM.               |
| `VBoxManage controlvm <VM_NAME> natpf1 delete <rule_name>` | Deletes the specified NAT port forwarding rule for the VM.              |
| `VBoxManage controlvm WINDOWS_SERVER natpf1 delete rdp`    | Deletes the "rdp" NAT port forwarding rule for the "WINDOWS_SERVER" VM. |

---

## **Vagrant Box Management**

| **Command**                                                              | **Description**                            |
|--------------------------------------------------------------------------|--------------------------------------------|
| `vagrant box list`                                                       | Lists all locally installed Vagrant boxes. |
| **Logs**: `C:\Users\<Your-User>\.vagrant.d\boxes\<box-name>\virtualbox\` | Path to the log files for Vagrant boxes.   |

---

## **Networking Commands**

| **Command**   | -               | **Description**                                                   |
|---------------|-----------------|-------------------------------------------------------------------|
| `netstat -ano | findstr :3389`  | Checks if port 3389 (RDP) is in use and displays process details. |
| `netstat -an  | findstr "3389"` | Verifies if port 3389 is listening or active.                     |

---

## **PowerShell Process Management**

| **Command**                      | **Description**                              |
|----------------------------------|----------------------------------------------|
| `Get-Process vagrant, ruby`      | Lists processes related to Vagrant and Ruby. |
| `Stop-Process -Name ruby -Force` | Terminates the Ruby process forcibly.        |

---

## **WinRM and Network Connectivity Testing**

| **Command**                                                                       | **Description**                                                                      |
|-----------------------------------------------------------------------------------|--------------------------------------------------------------------------------------|
| `Test-WsMan -ComputerName 127.0.0.1 -Port 55985`                                   | Tests if WinRM is active on the localhost (127.0.0.1) at port 55985.                  |
| `Test-NetConnection -ComputerName <VM_IP> -Port 55985`                             | Tests the network connection to the specified VM IP at port 55985.                    |
| `Test-NetConnection -ComputerName 127.0.0.1 -Port 55985`                           | Verifies network connection to localhost at port 55985.                               |
| `Enter-PSSession -ComputerName 127.0.0.1 -Port 55985 -Credential (New-Object...`   | Opens a PowerShell session with the localhost using WinRM and specified credentials. |
| `Enter-PSSession -ComputerName 127.0.0.1 -Port 55985 -Credential (Get-Credential)` | Initiates a PowerShell session using credentials obtained via `Get-Credential`.      |
| `Exit-PSSession`                                                                  | Closes the current PowerShell session.                                               |

Enter-PSSession -ComputerName 127.0.0.1 -Port 55985 -Credential (New-Object System.Management.Automation.PSCredential ("vagrant", (ConvertTo-SecureString "vagrant" -AsPlainText -Force)))
Enter-PSSession -ComputerName 127.0.0.1 -Port 55985 -Credential (New-Object System.Management.Automation.PSCredential ("ansible-agent", (ConvertTo-SecureString "ANS1BLE_P@sS!" -AsPlainText -Force)))

---

## **Network Utilities**

| **Command**        | **Description**                                      |
|--------------------|------------------------------------------------------|
| `Get-NetIPAddress` | Lists all IP addresses assigned to the local system. |

If you don't see the VM in the Virtual Box, then make sure that you run it as Administrator.

Rollback script:

Invoke-Command -ComputerName <VM_IP_OR_HOSTNAME> -Port 55985 -FilePath "C:\path\to\rollback.ps1" -Credential (New-Object System.Management.Automation.PSCredential ("vagrant", (ConvertTo-SecureString "vagrant" -AsPlainText -Force)))
Invoke-Command -ComputerName 127.0.0.1 -Port 55985 -FilePath ".\scripts\winrm_rollback.ps1" -Credential (New-Object System.Management.Automation.PSCredential ("vagrant", (ConvertTo-SecureString "vagrant" -AsPlainText -Force)))
Invoke-Command -ComputerName 127.0.0.1 -Port 55985 -FilePath ".\scripts\setup_ansible_user.ps1" -Credential (New-Object System.Management.Automation.PSCredential ("vagrant", (ConvertTo-SecureString "vagrant" -AsPlainText -Force)))
Invoke-Command -ComputerName 127.0.0.1 -Port 55985 -ArgumentList 192.168.56.189 -FilePath ".\scripts\check_ip.ps1" -Credential (New-Object System.Management.Automation.PSCredential ("vagrant", (ConvertTo-SecureString "vagrant" -AsPlainText -Force)))

Get-ChildItem -Path WSMan:\localhost\Listener

Enter-PSSession -ComputerName 127.0.0.1 -Port 55985 -Credential (New-Object System.Management.Automation.PSCredential ("ansible-agent", (ConvertTo-SecureString "ANS1BLE_P@sS!" -AsPlainText -Force))) -UseSSL -SkipCACheck
Enter-PSSession -ComputerName 127.0.0.1 -Port 55985 -Credential (New-Object System.Management.Automation.PSCredential ("ansible-agent", (ConvertTo-SecureString "ANS1BLE_P@sS!" -AsPlainText -Force))) -UseSSL -SkipCNCheck


Bypass ssl - trick, i think worked
$session = New-PSSession -ComputerName $vmIP -UseSSL -Authentication Default -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck)
Remove-PSSession $session
Test-WSMan -ComputerName $vmIP -Authentication Default



When running commands like Test-WSMan or Enter-PSSession from the host to the VM, use the host IP address (127.0.0.1) with the forwarded ports (55985 for HTTP or 55986 for HTTPS).

Test-WSMan -ComputerName 127.0.0.1 -Port 55985 -Authentication Default
Test-WSMan -ComputerName 127.0.0.1 -Port 55986 -Authentication Default -UseSSL


[Vagrant Cleanup](CLEANUP_README.md)