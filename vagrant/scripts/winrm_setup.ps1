<#
    .SYNOPSIS
        Configures WinRM and firewall rules for a Windows system.
    .DESCRIPTION
        This script enables PowerShell remoting, configures TrustedHosts,
        and sets up HTTP/HTTPS firewall rules for WinRM.
    .PARAMETER httpPort
        Port number for WinRM HTTP (default: 5985).
    .PARAMETER httpsPort
        Port number for WinRM HTTPS (default: 5986).
    .PARAMETER trustedHostsPath
        Path to configure TrustedHosts (default: WSMan:\localhost\Client\TrustedHosts).
    .PARAMETER trustedHosts
        A list of hosts to add to the TrustedHosts configuration. Use "*" to allow all hosts
        or specify a comma-separated list of specific hosts:
        (e.g., "192.168.1.1,server1.example.com").
    .NOTES
        Author: M. Faisal
#>

param (
    [int]$httpPort = 5985,
    [int]$httpsPort = 5986,
# TODO: use specific ip instead of *
    [string]$trustedHosts = "192.168.56.189", # Set "*" for all hosts, or specify specific IPs/hosts
    [string]$httpRuleName = "Allow WinRM HTTP",
    [string]$httpsRuleName = "Allow WinRM HTTPS",
    [string]$trustedHostsPath = "WSMan:\\localhost\\Client\\TrustedHosts"
)

function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $machineName = $env:COMPUTERNAME
    Write-Host "[$timestamp] [$machineName] $message"
}

function Check-CreateFirewallRule
{
    param (
        [string]$ruleName,
        [int]$port
    )
    Write-Log "Checking if firewall rule for $ruleName exists..."
    $rule = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
    if (-not $rule)
    {
        Write-Log "Creating firewall rule for $ruleName on port $port..."
        New-NetFirewallRule -Name $ruleName -Protocol TCP -LocalPort $port -Action Allow -DisplayName $ruleName
    }
    else
    {
        Write-Log "Firewall rule for $ruleName already exists."
    }
}


# Add the vagrant user to the Administrators group (if needed)
# $vagrantUser = "vagrant"
# Add-LocalGroupMember -Group "Administrators" -Member $vagrantUser
# Write-Output "$vagrantUser user added to Administrators"
#
# Admin Check (Optional: Uncomment if necessary)
# if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
#     Write-Log "Script must be run as Administrator."
#     exit 1
# }

# Enable and Configure WinRM
Write-Log "Enabling PowerShell Remoting..."
Enable-PSRemoting -Force

Write-Log "Setting WinRM service startup type to Automatic..."
Set-Service -Name WinRM -StartupType Automatic

Write-Log "Starting WinRM service..."
Start-Service -Name WinRM

Write-Log "Configuring TrustedHosts..."
Set-Item $trustedHostsPath -Value $trustedHosts -Force

# Configure Firewall Rules
Write-Log "Configuring HTTP firewall rule..."
Check-CreateFirewallRule -ruleName $httpRuleName -port $httpPort

Write-Log "Configuring HTTPS firewall rule..."
Check-CreateFirewallRule -ruleName $httpsRuleName -port $httpsPort

# Output Summary
Write-Log "Configuration Summary:"
Write-Log "TrustedHosts: $( Get-Item -Path $trustedHostsPath | Select-Object -ExpandProperty Value )"
Write-Log "Firewall Rules:"
Get-NetFirewallRule -Name $httpRuleName, $httpsRuleName -ErrorAction SilentlyContinue | Format-Table -Property Name, Enabled, Direction, LocalPort

Write-Log "WinRM configuration complete."
