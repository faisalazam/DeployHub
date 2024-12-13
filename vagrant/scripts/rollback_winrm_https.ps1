# Remove WinRM Listener for HTTPS
winrm delete winrm/config/Listener?Address=*+Transport=HTTPS

# Remove firewall rule for WinRM over HTTPS
Remove-NetFirewallRule -Name "WinRM-HTTPS"

# Stop and disable WinRM service
Stop-Service -Name WinRM
Set-Service -Name WinRM -StartupType Disabled

# Remove the certificate from the Windows certificate store
$thumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -match 'CN=winrm-https' }).Thumbprint
if ($thumbprint) {
    Remove-Item -Path "Cert:\LocalMachine\My\$thumbprint" -Force
}

# Clear WinRM Certificate Thumbprint if it exists
Remove-Item -Path "WSMan:\localhost\Service\CertificateThumbprint" -Force

# Remove trusted hosts configuration
Remove-Item -Path WSMan:\localhost\Client\TrustedHosts -Force

winrm quickconfig -q
