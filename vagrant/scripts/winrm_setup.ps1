# Add the vagrant user to the Administrators group (if needed)
# Add-LocalGroupMember -Group "Administrators" -Member "vagrant"
# Write-Output "vagrant user added to Administrators"

# Enable and configure WinRM
Write-Host "Enabling PowerShell Remoting..."
Enable-PSRemoting -Force

Write-Host "Setting WinRM service startup type to Automatic..."
Set-Service -Name WinRM -StartupType Automatic

Write-Host "Starting WinRM service..."
Start-Service -Name WinRM

Write-Host "Configuring TrustedHosts..."
Set-Item WSMan:\\localhost\\Client\\TrustedHosts -Value "*" -Force

# Check if WinRM HTTP rule already exists, create if it doesn't
Write-Host "Checking if firewall rule for WinRM HTTP exists..."
$httpRule = Get-NetFirewallRule -Name 'Allow WinRM HTTP' -ErrorAction SilentlyContinue
if (-not $httpRule) {
    Write-Host "Creating firewall rule for WinRM HTTP on port 5985..."
    New-NetFirewallRule -Name 'Allow WinRM HTTP' -Protocol TCP -LocalPort 5985 -Action Allow -DisplayName 'Allow WinRM HTTP'
} else {
    Write-Host "Firewall rule for WinRM HTTP already exists."
}

# Check if WinRM HTTPS rule already exists, create if it doesn't
Write-Host "Checking if firewall rule for WinRM HTTPS exists..."
$httpsRule = Get-NetFirewallRule -Name 'Allow WinRM HTTPS' -ErrorAction SilentlyContinue
if (-not $httpsRule) {
    Write-Host "Creating firewall rule for WinRM HTTPS on port 5986..."
    New-NetFirewallRule -Name 'Allow WinRM HTTPS' -Protocol TCP -LocalPort 5986 -Action Allow -DisplayName 'Allow WinRM HTTPS'
} else {
    Write-Host "Firewall rule for WinRM HTTPS already exists."
}

# Output confirmation
Write-Output "WinRM configured"
