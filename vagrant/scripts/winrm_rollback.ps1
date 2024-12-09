<#
    .SYNOPSIS
        Rolls back the changes made by the WinRM configuration script.
    .DESCRIPTION
        This script disables PowerShell remoting, resets TrustedHosts to its default value,
        removes custom HTTP/HTTPS firewall rules, and stops the WinRM service.
    .NOTES
        Author: M. Faisal
#>

param (
    [string]$trustedHostsPath = "WSMan:\\localhost\\Client\\TrustedHosts",
    [string]$httpRuleName = "Allow WinRM HTTP",
    [string]$httpsRuleName = "Allow WinRM HTTPS"
)

function Write-Log
{
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $message"
}

function Remove-FirewallRuleIfExists
{
    param ([string]$ruleName)
    Write-Log "Checking if firewall rule $ruleName exists..."
    $rule = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
    if ($rule)
    {
        Write-Log "Removing firewall rule $ruleName..."
        Remove-NetFirewallRule -Name $ruleName
    }
    else
    {
        Write-Log "Firewall rule $ruleName does not exist."
    }
}

# Disable PowerShell Remoting
Write-Log "Disabling PowerShell Remoting..."
Disable-PSRemoting -Force

# Stop and disable WinRM service
Write-Log "Stopping WinRM service..."
Stop-Service -Name WinRM -Force

Write-Log "Setting WinRM service startup type to Manual..."
Set-Service -Name WinRM -StartupType Manual

# Reset TrustedHosts to default (empty)
Write-Log "Resetting TrustedHosts to default..."
Set-Item $trustedHostsPath -Value "" -Force

# Remove Firewall Rules
Write-Log "Removing HTTP firewall rule..."
Remove-FirewallRuleIfExists -ruleName $httpRuleName

Write-Log "Removing HTTPS firewall rule..."
Remove-FirewallRuleIfExists -ruleName $httpsRuleName

# Output Summary
Write-Log "Rollback Summary:"
Write-Log "TrustedHosts reset to: $( Get-Item -Path $trustedHostsPath | Select-Object -ExpandProperty Value )"
Write-Log "WinRM service stopped and set to Manual startup."
Write-Log "Custom firewall rules removed."

Write-Log "Rollback complete."
