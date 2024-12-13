# Define variables for hardcoded values
$certCN = "winrm-https"
$winrmServiceName = "WinRM"
$firewallRuleName = "WinRM-HTTPS"
$winrmListenerAddress = "*+Transport=HTTPS"
$certStoreLocation = "Cert:\LocalMachine\My"
$wsmanServiceLocation = "WSMan:\localhost\Service"
$trustedHostsLocation = "WSMan:\localhost\Client\TrustedHosts"

# Remove WinRM Listener for HTTPS
Write-Host "[INFO] Removing WinRM Listener for HTTPS..."
try {
    winrm delete winrm/config/Listener?Address=$winrmListenerAddress
} catch {
    Write-Host "[WARNING] Failed to remove WinRM Listener for HTTPS. It may not exist."
}

# Remove firewall rule for WinRM over HTTPS
Write-Host "[INFO] Removing firewall rule for WinRM over HTTPS..."
try {
    Remove-NetFirewallRule -Name $firewallRuleName -ErrorAction Stop
} catch {
    Write-Host "[WARNING] Failed to remove WinRM firewall rule. It may not exist."
}

# Stop and disable WinRM service
Write-Host "[INFO] Stopping and disabling WinRM service..."
try {
    Stop-Service -Name $winrmServiceName -ErrorAction Stop
    Set-Service -Name $winrmServiceName -StartupType Disabled -ErrorAction Stop
} catch {
    Write-Host "[WARNING] Failed to stop or disable the WinRM service. It may already be stopped."
}

# Remove the certificate from the Windows certificate store
Write-Host "[INFO] Removing the certificate from the Windows certificate store..."
$thumbprint = (Get-ChildItem -Path $certStoreLocation | Where-Object { $_.Subject -match "CN=$certCN" }).Thumbprint
if ($thumbprint) {
    try {
        Remove-Item -Path "$certStoreLocation\$thumbprint" -Force -ErrorAction Stop
    } catch {
        Write-Host "[WARNING] Failed to remove certificate from the store. It may not exist."
    }
} else {
    Write-Host "[WARNING] No certificate with CN=$certCN found in the store."
}

# Clear WinRM Certificate Thumbprint if it exists
Write-Host "[INFO] Clearing WinRM Certificate Thumbprint..."
try {
    Remove-Item -Path "$wsmanServiceLocation\CertificateThumbprint" -Force -ErrorAction Stop
} catch {
    Write-Host "[WARNING] Failed to clear the WinRM Certificate Thumbprint. It may not exist."
}

# Remove trusted hosts configuration
Write-Host "[INFO] Removing trusted hosts configuration..."
try {
    Remove-Item -Path $trustedHostsLocation -Force -ErrorAction Stop
} catch {
    Write-Host "[WARNING] Failed to remove trusted hosts configuration. It may not exist."
}

# Re-run WinRM quickconfig
Write-Host "[INFO] Re-running WinRM quickconfig..."
try {
    winrm quickconfig -q
} catch {
    Write-Host "[ERROR] Failed to re-run WinRM quickconfig."
}

Write-Host "[INFO] WinRM cleanup completed."
