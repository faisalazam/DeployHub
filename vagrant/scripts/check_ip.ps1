# Ensure that the VM_IP is provided as a parameter
param (
    [Parameter(Mandatory = $true)]
    [string]$VM_IP
)

function Write-Log
{
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $machineName = $env:COMPUTERNAME
    Write-Host "[$timestamp] [$machineName] $message"
}

# Find the network adapter with the specific static IP
$networkAdapter = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -eq $VM_IP
}

if ($networkAdapter)
{
    # Log success and notify the user
    Write-Log "Static IP is correctly set to $VM_IP"
}
else
{
    # Get the current IP and log a warning
    $currentIP = (Get-NetIPAddress -AddressFamily IPv4).IPAddress
    Write-Log "Warning: Static IP is not set to $VM_IP. Current IP(s): $currentIP"
}
