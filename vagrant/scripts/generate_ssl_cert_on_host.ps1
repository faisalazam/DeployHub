param (
    [int]$KeyLength = 2048,
    [int]$CertValidityYears = 1,
    [string]$CertPath = ".\certs",
    [string]$CertCN = "localhost",
    [string]$CertPass = "YourCertPassword",
    [string[]]$DnsNames = @("localhost", "127.0.0.1"),
    [string]$CertExportFileName = "winrm-cert.pfx",
    [string]$CertStoreLocation = "Cert:\LocalMachine\My",
    [string]$TrustedRootStoreLocation = "Cert:\LocalMachine\Root",
    [string]$FriendlyName = "FAISAL - WinRM Self Signed Root Certificate For Windows Vagrant VM"
)

function Write-Log {
    param (
        [string]$message,
        [string]$logLevel = "INFO"
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "$timestamp [$logLevel] $message"
}

# Error handling function
function Handle-Error {
    param (
        [string]$errorMessage
    )
    Write-Log -message $errorMessage -logLevel "ERROR"
    exit 1
}

try {
    # Step 1: Create the directory to store the certificates if it doesn't exist
    if (-not (Test-Path -Path $CertPath)) {
        Write-Log -message "Creating certificate directory: $CertPath"
        New-Item -ItemType Directory -Path $CertPath | Out-Null
    }

    # Step 2: Generate a self-signed certificate with DNS names
    Write-Log -message "Generating self-signed certificate for $CertCN with DNS names: $($DnsNames -join ', ')..."
    $dnsNamesString = $($DnsNames -join ', ')  # Join the DNS names into a single string
    $cert = New-SelfSignedCertificate -CertStoreLocation $CertStoreLocation `
        -DnsName $DnsNames `
        -KeyAlgorithm RSA `
        -KeyLength $KeyLength `
        -KeyExportPolicy Exportable `
        -KeyUsage DigitalSignature, KeyEncipherment `
        -NotAfter (Get-Date).AddYears($CertValidityYears) `
        -Type SSLServerAuthentication

    if (-not $cert) {
        Handle-Error -errorMessage "Failed to generate certificate."
    }

    # Step 3: Set FriendlyName to the certificate using the certificate's Thumbprint
    Write-Log -message "Setting FriendlyName for the certificate..."
    $cert.FriendlyName = $FriendlyName

    # Step 4: Export the certificate to a PFX file
    $CertFile = Join-Path $CertPath $CertExportFileName
    Write-Log -message "Exporting certificate to PFX file: $CertFile"

    Export-PfxCertificate -Cert $cert `
        -FilePath $CertFile `
        -Password (ConvertTo-SecureString -String $CertPass -AsPlainText -Force)

    Write-Log -message "Certificate exported successfully to: $CertFile"

    # Step 5: Import the certificate into the Trusted Root Certification Authorities store
    Write-Log -message "Importing certificate into Trusted Root Certification Authorities store..."

    Import-PfxCertificate -FilePath $CertFile `
        -CertStoreLocation $TrustedRootStoreLocation `
        -Password (ConvertTo-SecureString -String $CertPass -AsPlainText -Force)

    Write-Log -message "Certificate imported successfully into Trusted Root store."

    # Step 6: Verify the installation by listing certificates in the Trusted Root store
    Write-Log -message "Verifying certificate installation in Trusted Root store..."

    # Check if certificate with CN exists in the Trusted Root store
    $installedCert = Get-ChildItem -Path $TrustedRootStoreLocation `
        | Where-Object { $_.Subject -match "CN=$CertCN" }

    if (-not $installedCert) {
        Handle-Error -errorMessage "Certificate not found in Trusted Root store."
    }

    Write-Log -message "Certificate successfully installed and verified in Trusted Root store."
} catch {
    Handle-Error -errorMessage "An error occurred: $_"
}
