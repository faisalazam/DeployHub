# Add the vagrant user to the Administrators group
# Add-LocalGroupMember -Group "Administrators" -Member "vagrant"
# Write-Output "vagrant user added to Administrators"

# Enable and configure WinRM
Enable-PSRemoting -Force
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM
Set-Item WSMan:\\localhost\\Client\\TrustedHosts -Value "*" -Force
New-NetFirewallRule -Name "Allow WinRM HTTP" -Protocol TCP -LocalPort 5985 -Action Allow
New-NetFirewallRule -Name "Allow WinRM HTTPS" -Protocol TCP -LocalPort 5986 -Action Allow

# Output confirmation
Write-Output "WinRM configured"
