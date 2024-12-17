# Define configurable parameters
$CertCN = "localhost"
$certPath = "C:\certs"
$WinRMGuestPort = 5986
$RoleName = "Administrator"
$certPass = "YourCertPassword"
$certFile = "$certPath\certificate.pfx"
$FirewallRuleName = "WinRM-HTTPS"
$winrmPath = "WSMan:\localhost\Service"
$trustedHosts = "127.0.0.1,local_windows_vm"
$trustedHostsLocation = "WSMan:\localhost\Client\TrustedHosts"

# Function for error handling
function Handle-Error {
    param([string]$ErrorMessage)
    Write-Host "[ERROR] $ErrorMessage"
    exit 1
}

# Check if script is running as Administrator
Write-Host "[INFO] Checking if script is running as $RoleName..."
try {
    if (-not ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "$RoleName")) {

        Write-Host "[INFO] Restarting script as $RoleName..."
        Start-Process powershell.exe -ArgumentList `
            "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
            -Verb RunAs
        exit
    }
} catch {
    Handle-Error "Failed to check for Administrator role."
}

if (-not (Test-Path $certPath)) {
    Handle-Error "No certificate found at $certPath"
}

# Proceed with your script
Write-Host "[INFO] Found $certPath. Proceeding with setup..."

# Ensure the certificate exists on the VM
if (-not (Test-Path -Path $certFile)) {
    Handle-Error "Certificate file not found. Ensure the certificate is transferred to the VM."
}

# Install the certificate in the Windows certificate store if not already installed
Write-Host "[INFO] Installing certificate in the Windows certificate store..."
$existingCert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -match "CN=$CertCN" }
if (-not $existingCert) {
    try {
        $secureCertPass = ConvertTo-SecureString -String $certPass -AsPlainText -Force
        Import-PfxCertificate -FilePath $certFile -CertStoreLocation "Cert:\LocalMachine\My" -Password $secureCertPass
    } catch {
        Handle-Error "Failed to install the certificate."
    }
} else {
    Write-Host "[INFO] Certificate already installed."
}

# Ensure WinRM service is running
try {
    if ((Get-Service -Name WinRM).Status -ne 'Running') {
        Start-Service -Name WinRM
    }
} catch {
    Handle-Error "Failed to start the WinRM service."
}

# Check if WinRM is already configured
try {
    $winrmConfig = winrm get winrm/config
    if ($winrmConfig -match "Enabled\s*=\s*true") {
        Write-Host "[INFO] WinRM is already configured."
    } else {
        Write-Host "[INFO] Configuring WinRM..."
        winrm quickconfig -q
    }
} catch {
    Handle-Error "Failed to get or configure WinRM."
}

# Retrieve the thumbprint of the certificate
$thumbprint = ""
try {
    $thumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My `
                    | Where-Object { $_.Subject -match "CN=$CertCN" }).Thumbprint
    if (-not $thumbprint) {
        Handle-Error "Certificate thumbprint not found."
    }
} catch {
    Handle-Error "Failed to retrieve certificate thumbprint."
}

# Set trusted hosts to allow remote connections
if ($trustedHosts -ne $trustedHosts) {
    try {
        Set-Item -Path $trustedHostsLocation -Value $trustedHosts -Force
    } catch {
        Handle-Error "Failed to set TrustedHosts."
    }
} else {
    Write-Host "[INFO] TrustedHosts already set to $trustedHosts."
}

# Ensure AllowUnencrypted is set to false
try {
    Set-Item -Path "$winrmPath\AllowUnencrypted" -Value $false
} catch {
    Handle-Error "Failed to set AllowUnencrypted."
}

# Configure the CertificateThumbprint for HTTPS
try {
    Set-Item -Path "$winrmPath\CertificateThumbprint" -Value $thumbprint
} catch {
    Handle-Error "Failed to set CertificateThumbprint."
}

# Retrieve the current listeners
Write-Host "[INFO] Checking for existing WinRM listeners..."
$existingListener = winrm enumerate winrm/config/Listener | Where-Object { $_ -match "Transport = HTTPS" }

# If the listener does not exist, create it
if (-not $existingListener) {
    Write-Host "[INFO] Configuring WinRM listener for HTTPS..."
    $listenerConfig = '@{Hostname="";CertificateThumbprint="' + $thumbprint + '";Port="' + $WinRMGuestPort + '"}'
    try {
        $command = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '$listenerConfig'"
        Invoke-Expression $command
        Write-Host "[INFO] Created WinRM listener for HTTPS."
    } catch {
        Handle-Error "Failed to configure WinRM listener for HTTPS."
    }
} else {
    Write-Host "[INFO] WinRM listener for HTTPS already exists. Skipping creation."
}

Write-Host "[INFO] Validating the Listener..."
try {
    winrm enumerate winrm/config/Listener
} catch {
    Handle-Error "Failed to validate WinRM listener configuration."
}

# Check and add firewall rule for HTTPS
try {
    if (-not (Get-NetFirewallRule -Name $FirewallRuleName -ErrorAction SilentlyContinue)) {
        Write-Host "[INFO] Adding firewall rule for WinRM over HTTPS..."
        New-NetFirewallRule -DisplayName "Allow WinRM over HTTPS" -Name $FirewallRuleName `
                            -Protocol TCP -LocalPort $WinRMGuestPort -Action Allow
    } else {
        Write-Host "[INFO] Firewall rule for WinRM over HTTPS already exists."
    }
} catch {
    Handle-Error "Failed to add or check the firewall rule."
}

## Restart the WinRM service to apply changes
#Write-Host "[INFO] Restarting WinRM service..."
#Restart-Service -Name WinRM

Write-Host "[INFO] WinRM over HTTPS has been successfully configured."
Write-Host "[INFO] Skipping WinRM restart (as it is likely unnecessary) to maintain connection."
