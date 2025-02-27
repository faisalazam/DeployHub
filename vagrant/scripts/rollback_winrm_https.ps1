# BETTER TO RUN THIS FROM WITHIN THE MACHINE INSTEAD OF REMOTE COMMAND
# AS THE CONNECTION WILL BREAK DUE TO THE RESTART OF THE WINRM SERVICE.

# Define variables for hardcoded values
$certCN = "localhost"
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
    Write-Host "[WARNING] Failed to remove WinRM Listener for HTTPS. It may not exist or was already removed."
}

# Remove firewall rule for WinRM over HTTPS
Write-Host "[INFO] Removing firewall rule for WinRM over HTTPS..."
try {
    Remove-NetFirewallRule -Name $firewallRuleName -ErrorAction Stop
} catch {
    Write-Host "[WARNING] Failed to remove WinRM firewall rule. It may not exist or was already removed."
}

# Stop and disable WinRM service
Write-Host "[INFO] Stopping and disabling WinRM service..."
try {
    Stop-Service -Name $winrmServiceName -ErrorAction Stop
    Set-Service -Name $winrmServiceName -StartupType Disabled -ErrorAction Stop
} catch {
    Write-Host "[WARNING] Failed to stop or disable the WinRM service. It may already be stopped or disabled."
}

# Remove the certificate from the Windows certificate store
Write-Host "[INFO] Removing the certificate from the Windows certificate store..."
$cert = Get-ChildItem -Path $certStoreLocation | Where-Object { $_.Subject -match "CN=$certCN" }
if ($cert) {
    $thumbprint = $cert.Thumbprint
    try {
        Remove-Item -Path "$certStoreLocation\$thumbprint" -Force -ErrorAction Stop
        Write-Host "[INFO] Certificate with CN=$certCN removed successfully."
    } catch {
        Write-Host "[WARNING] Failed to remove certificate from the store. It may not exist or was already removed."
    }
} else {
    Write-Host "[WARNING] No certificate with CN=$certCN found in the store."
}

# Clear WinRM Certificate Thumbprint if it exists
Write-Host "[INFO] Clearing WinRM Certificate Thumbprint..."
try {
    Remove-Item -Path "$wsmanServiceLocation\CertificateThumbprint" -Force -ErrorAction Stop
    Write-Host "[INFO] WinRM Certificate Thumbprint cleared."
} catch {
    Write-Host "[WARNING] Failed to clear the WinRM Certificate Thumbprint. It may not exist or was already cleared."
}

# Remove trusted hosts configuration
Write-Host "[INFO] Removing trusted hosts configuration..."
try {
    Remove-Item -Path $trustedHostsLocation -Force -ErrorAction Stop
    Write-Host "[INFO] Trusted hosts configuration removed."
} catch {
    Write-Host "[WARNING] Failed to remove trusted hosts configuration. It may not exist or was already removed."
}

# Re-run WinRM quickconfig
Write-Host "[INFO] Re-running WinRM quickconfig..."
try {
    winrm quickconfig -q
    Write-Host "[INFO] WinRM quickconfig re-ran successfully."
} catch {
    Write-Host "[ERROR] Failed to re-run WinRM quickconfig."
}

Write-Host "[INFO] WinRM cleanup completed."
