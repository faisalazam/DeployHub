# Define paths for certificate and password
$certPath = "C:\certs"
$certFile = "$certPath\winrm-cert.pfx"
$privateKey = "$certPath\winrm-cert.key"
$certPass = "YourCertPassword"  # Password for the PFX file

# Create the directory to store the certificates if it doesn't exist
if (-not (Test-Path -Path $certPath)) {
    New-Item -ItemType Directory -Path $certPath
}

# Generate a self-signed certificate
Write-Host "[INFO] Generating self-signed certificate..."
$cert = New-SelfSignedCertificate -CertStoreLocation "Cert:\LocalMachine\My" -DnsName "winrm-https" -KeyAlgorithm RSA -KeyLength 2048 -NotAfter (Get-Date).AddYears(1) -KeyExportPolicy Exportable

# Export the certificate to a PFX file
Write-Host "[INFO] Exporting certificate to PFX..."
Export-PfxCertificate -Cert $cert -FilePath $certFile -Password (ConvertTo-SecureString -String $certPass -AsPlainText -Force)

# Ensure WinRM service is running
if ((Get-Service -Name WinRM).Status -ne 'Running') {
    Start-Service -Name WinRM
}

# Configure WinRM
Write-Host "[INFO] Configuring WinRM..."
winrm quickconfig -q

# Install the certificate in the Windows certificate store
Write-Host "[INFO] Installing certificate in the Windows certificate store..."
Import-PfxCertificate -FilePath $certFile -CertStoreLocation "Cert:\LocalMachine\My" -Password (ConvertTo-SecureString -String $certPass -AsPlainText -Force)

# Configure WinRM to use HTTPS
Write-Host "[INFO] Configuring WinRM to use HTTPS..."
$thumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -match 'CN=winrm-https' }).Thumbprint

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

# Check and add firewall rule for HTTPS
if (-not (Get-NetFirewallRule -Name "WinRM-HTTPS" -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] Adding firewall rule for WinRM over HTTPS..."
    New-NetFirewallRule -DisplayName "Allow WinRM over HTTPS" -Name "WinRM-HTTPS" -Protocol TCP -LocalPort 5986 -Action Allow
#    New-NetFirewallRule -DisplayName "Allow WinRM over HTTPS" -Name "WinRM-HTTPS" -Profile Any -Protocol TCP -LocalPort 5986 -Action Allow
} else {
    Write-Host "[INFO] Firewall rule for WinRM over HTTPS already exists."
}

# Restart the WinRM service to apply changes
Write-Host "[INFO] Restarting WinRM service..."
Restart-Service -Name WinRM

Write-Host "[INFO] WinRM over HTTPS has been successfully configured."
