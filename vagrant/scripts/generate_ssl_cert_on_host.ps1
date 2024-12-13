# Define paths for certificate and password
$certPath = ".\certs"
$certPass = "YourCertPassword"
$certFile = "$certPath\winrm-cert.pfx"
$certCN = "FAISAL - WinRM Self Signed Root Certificate For Windows Vagrant VM"

# Create the directory to store the certificates if it doesn't exist
if (-not (Test-Path -Path $certPath))
{
    New-Item -ItemType Directory -Path $certPath
}

# Generate a self-signed certificate with a unique CN (e.g., "My-WinRM-Cert")
Write-Host "[INFO] Generating self-signed certificate for $certCN..."
$cert = New-SelfSignedCertificate -CertStoreLocation "Cert:\LocalMachine\My" `
    -DnsName $certCN, "localhost", "127.0.0.1" `
    -KeyAlgorithm RSA -KeyLength 2048 `
    -NotAfter (Get-Date).AddYears(1) `
    -KeyExportPolicy Exportable `
    -KeyUsage DigitalSignature, KeyEncipherment `
    -Type SSLServerAuthentication

# Export the certificate to a PFX file
Write-Host "[INFO] Exporting certificate to PFX..."
Export-PfxCertificate -Cert $cert -FilePath $certFile -Password (ConvertTo-SecureString -String $certPass -AsPlainText -Force)

Write-Host "[INFO] Certificate exported successfully. Transfer the PFX file to the VM."

# Import the certificate into the Trusted Root Certification Authorities store
Write-Host "[INFO] Installing certificate into the Trusted Root Certification Authorities store..."
Import-PfxCertificate -FilePath $certFile -CertStoreLocation "Cert:\LocalMachine\Root" -Password (ConvertTo-SecureString -String $certPass -AsPlainText -Force)

# Verify the installation by listing certificates in the Trusted Root store
Write-Host "[INFO] Verifying certificate installation in Trusted Root store..."
Get-ChildItem -Path "Cert:\LocalMachine\Root" | Where-Object { $_.Subject -match "CN=$certCN" }

Write-Host "[INFO] Certificate installation completed."
