# Define paths for certificate and password
$CertCN = "localhost"
$certPath = "C:\certs"
$certPass = "YourCertPassword"
$certFile = "$certPath\winrm-cert.pfx"

# Ensure the certificate exists on the VM
if (-not (Test-Path -Path $certFile)) {
    Write-Host "[ERROR] Certificate file not found. Ensure the certificate is transferred to the VM."
    exit
}

# Install the certificate in the Windows certificate store
Write-Host "[INFO] Installing certificate in the Windows certificate store..."
Import-PfxCertificate -FilePath $certFile -CertStoreLocation "Cert:\LocalMachine\My" -Password (ConvertTo-SecureString -String $certPass -AsPlainText -Force)

# Ensure WinRM service is running
if ((Get-Service -Name WinRM).Status -ne 'Running') {
    Start-Service -Name WinRM
}

# Configure WinRM
Write-Host "[INFO] Configuring WinRM..."
winrm quickconfig -q

# Retrieve the thumbprint of the certificate
$thumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -match "CN=$CertCN" }).Thumbprint

# Set trusted hosts to allow remote connections
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

# Configure the WinRM service for SSL
$winrmPath = "WSMan:\localhost\Service"

# Ensure AllowUnencrypted is set to false
Set-Item -Path "$winrmPath\AllowUnencrypted" -Value $false

# Configure the CertificateThumbprint for HTTPS
Set-Item -Path "$winrmPath\CertificateThumbprint" -Value $thumbprint

# Configure the WinRM listener for HTTPS
Write-Host "[INFO] Configuring WinRM listener for HTTPS..."
$listenerConfig = '@{Hostname="";CertificateThumbprint="' + $thumbprint + '";Port="5986"}'
$command = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '$listenerConfig'"
Invoke-Expression $command

Write-Host "[INFO] Validating the Listener..."
winrm enumerate winrm/config/Listener

# Check and add firewall rule for HTTPS
if (-not (Get-NetFirewallRule -Name "WinRM-HTTPS" -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] Adding firewall rule for WinRM over HTTPS..."
    New-NetFirewallRule -DisplayName "Allow WinRM over HTTPS" -Name "WinRM-HTTPS" -Protocol TCP -LocalPort 5986 -Action Allow
} else {
    Write-Host "[INFO] Firewall rule for WinRM over HTTPS already exists."
}

# Restart the WinRM service to apply changes
Write-Host "[INFO] Restarting WinRM service..."
Restart-Service -Name WinRM

Write-Host "[INFO] WinRM over HTTPS has been successfully configured."
