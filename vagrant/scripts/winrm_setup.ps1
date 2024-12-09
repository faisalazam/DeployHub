$httpPort = 5985
$httpsPort = 5986
$httpRuleName = 'Allow WinRM HTTP'
$httpsRuleName = 'Allow WinRM HTTPS'
$trustedHostsPath = "WSMan:\\localhost\\Client\\TrustedHosts"
$trustedHosts = "*"  # Set "*" for all hosts, or specify specific IPs/hosts

# Function to check and create firewall rule
function Check-CreateFirewallRule {
    param (
        [string]$ruleName,
        [int]$port
    )

    Write-Host "Checking if firewall rule for $ruleName exists..."
    $rule = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
    if (-not $rule) {
        Write-Host "Creating firewall rule for $ruleName on port $port..."
        New-NetFirewallRule -Name $ruleName -Protocol TCP -LocalPort $port -Action Allow -DisplayName $ruleName
    } else {
        Write-Host "Firewall rule for $ruleName already exists."
    }
}

# Add the vagrant user to the Administrators group (if needed)
# $vagrantUser = "vagrant"
# Add-LocalGroupMember -Group "Administrators" -Member $vagrantUser
# Write-Output "$vagrantUser user added to Administrators"

# Enable and configure WinRM
Write-Host "Enabling PowerShell Remoting..."
Enable-PSRemoting -Force

Write-Host "Setting WinRM service startup type to Automatic..."
Set-Service -Name WinRM -StartupType Automatic

Write-Host "Starting WinRM service..."
Start-Service -Name WinRM

Write-Host "Configuring TrustedHosts..."
Set-Item $trustedHostsPath -Value $trustedHosts -Force

# Check and create firewall rules for WinRM HTTP and HTTPS
Check-CreateFirewallRule -ruleName $httpRuleName -port $httpPort
Check-CreateFirewallRule -ruleName $httpsRuleName -port $httpsPort

# Output confirmation
Write-Output "WinRM configured"
