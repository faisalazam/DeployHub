Complete Cleanup of Vagrant and VirtualBox
To completely clean up Vagrant and VirtualBox and ensure no residual configuration or corrupted states are causing issues, follow these steps:

```bash
vagrant global-status --prune
vagrant destroy <id>
vagrant global-status --prune | grep virtualbox | awk '{print $1}' | xargs vagrant destroy -f

# OPTIONAL - it'll remove the downloaded base boxes
vagrant box list | awk '{print $1}' | xargs -I {} vagrant box remove {}

find ~ -type d -name ".vagrant" -exec rm -rf {} +

VBoxManage list vms
VBoxManage list vms | awk -F'"' '{print $2}' | xargs -I {} VBoxManage controlvm "{}" poweroff
VBoxManage list runningvms | awk -F'"' '{print $2}' | xargs -I {} VBoxManage controlvm "{}" poweroff
VBoxManage list vms | awk -F'"' '{print $2}' | xargs -I {} VBoxManage unregistervm "{}" --delete

rm -rf ~/.vagrant.d
find ~/.vagrant.d -type l -exec rm -f {} \;
rm -rf ~/VirtualBox\ VMs/
rm -rf ~/.config/VirtualBox/
# For macOS
rm -rf ~/Library/VirtualBox/

VBoxManage list hostonlyifs
VBoxManage list hostonlyifs | grep "^Name:" | awk -F': ' '{print $2}' | xargs -I {} VBoxManage hostonlyif remove {}

# If the above command doesn't work
VBoxManage hostonlyif remove "VirtualBox Host-Only <Adapter Name>"
VBoxManage hostonlyif remove "VirtualBox Host-Only Ethernet Adapter"
VBoxManage hostonlyif remove "VirtualBox Host-Only Ethernet Adapter #2"
VBoxManage hostonlyif remove "VirtualBox Host-Only Ethernet Adapter #3"
```

See below for explanation.

1. Destroy Existing Vagrant Machines
   Run the following command to destroy all Vagrant-managed virtual machines:

`vagrant global-status --prune`

This lists all Vagrant machines. Destroy them using:

`vagrant destroy <id>`

Or to destroy all machines at once:

`vagrant global-status --prune | grep virtualbox | awk '{print $1}' | xargs vagrant destroy -f`

2. Remove Vagrant Files and Boxes
   Delete All Vagrant Boxes (it'll delete the downloaded actual base boxes) - OPTIONAL:
   `vagrant box list | awk '{print $1}' | xargs -I {} vagrant box remove {}`

Manually Clear Residual .vagrant Directories:
`find ~ -type d -name ".vagrant" -exec rm -rf {} +`

This removes .vagrant folders in your home directory and any projects.

3. Clean VirtualBox
   Unregister and Remove All VirtualBox VMs
   List All VMs:
   `VBoxManage list vms`

Poweroff All VMs:
`VBoxManage list vms | awk -F'"' '{print $2}' | xargs -I {} VBoxManage controlvm "{}" poweroff`

Or if some VMs are still running:

`VBoxManage list runningvms | awk -F'"' '{print $2}' | xargs -I {} VBoxManage controlvm "{}" poweroff`

Unregister and Delete VMs:
`VBoxManage list vms | awk -F'"' '{print $2}' | xargs -I {} VBoxManage unregistervm "{}" --delete`

Delete VirtualBox Settings
Remove configuration files:

```bash
rm -rf ~/VirtualBox\ VMs/
rm -rf ~/.config/VirtualBox/
rm -rf ~/Library/VirtualBox/ # For macOS
```

Clear VirtualBox Host-Only Network Adapters
Sometimes network conflicts cause Vagrant failures. Clear host-only adapters:

List Adapters:
`VBoxManage list hostonlyifs`

Delete Adapters:
`VBoxManage list hostonlyifs | grep "^Name:" | awk -F': ' '{print $2}' | xargs -I {} VBoxManage hostonlyif remove {}`

If that command fails, use:

`VBoxManage hostonlyif remove "VirtualBox Host-Only <Adapter Name>"`

Example:

```bash
VBoxManage hostonlyif remove "VirtualBox Host-Only Ethernet Adapter"
VBoxManage hostonlyif remove "VirtualBox Host-Only Ethernet Adapter #2"
VBoxManage hostonlyif remove "VirtualBox Host-Only Ethernet Adapter #3"
```


[Go back to Vagrant](README.md)
