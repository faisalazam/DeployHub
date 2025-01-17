param (
    [int]$KeyLength = 4096,
    [int]$CertValidityYears = 1,
    [string]$CertCN = "localhost",
    [string]$CertPath = "..\certs\local",
    # TODO: Store/inject the password somewhere else - confidential
    [string]$CertPass = "YourCertPassword",
    [string]$CertPfxExportFileName = "certificate.pfx",
    [string]$CertPemExportFileName = "certificate.pem",
    [string]$FriendlyName = "FAISAL-WinRM-SelfSigned-WinVM",
    [string[]]$DnsNames = @($CertCN, "127.0.0.1", "local_windows_vm")
)

$CertStoreLocation = "Cert:\LocalMachine\My"
$TrustedRootStoreLocation = "Cert:\LocalMachine\Root"
$CertificationAuthorityStoreLocation = "Cert:\LocalMachine\CA"

function Write-Log {
    param (
        [string]$message,
        [string]$logLevel = "INFO"
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "$timestamp [$logLevel] $message"
}

# Check if the directory exists and is empty
if (Test-Path -Path $CertPath) {
    $certFiles = Get-ChildItem -Path $CertPath
    if ($certFiles.Count -gt 0) {
        Write-Log -message "Certificate directory already exists and is not empty. Skipping certificate generation."
        exit 0
    }
} else {
    Write-Log -message "Certificate directory does not exist. Proceeding with certificate generation..."
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
    # Step 1: Clean up existing certificates before generating a new one
    Write-Log -message "Cleaning up existing certificates with FriendlyName pattern: $FriendlyName"
    $removeCertScriptPath = ".\scripts\remove_certs_from_stores.ps1"
    if (Test-Path $removeCertScriptPath) {
        & $removeCertScriptPath -FriendlyNamePattern "$FriendlyName"
    } else {
        Handle-Error -errorMessage "remove_certs_from_stores.ps1 script not found."
    }

    # Step 2: Create the directory to store the certificates if it doesn't exist
    if (-not (Test-Path -Path $CertPath)) {
        Write-Log -message "Creating certificate directory: $CertPath"
        New-Item -ItemType Directory -Path $CertPath | Out-Null
    }

    # Step 3: Generate a self-signed certificate with DNS names
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

    # Step 4: Set FriendlyName to the certificates using the certificate's Thumbprint
    Write-Log -message "Setting FriendlyName for the certificates..."
    $cert.FriendlyName = $FriendlyName

    # New-SelfSignedCertificate generates the cert in $CertStoreLocation as well as in $CertificationAuthorityStoreLocation,
    # So, have to set the FriendlyName explicity as it won't get propagated automatically.
    # We're interesting in setting it as we use it in the ".\scripts\remove_certs_from_stores.ps1" script to cleaup.
    # So, if it is not set, then it won't get cleaned up.
    # So, the following will set it in Cert:\LocalMachine\CA and Cert:\CurrentUser\CA stores.
    $certInStore = Get-ChildItem -Path $CertificationAuthorityStoreLocation `
                | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
    if ($certInStore) {
        $certInStore.FriendlyName = $FriendlyName
    } else {
        Write-Host "Certificate not found in $CertificationAuthorityStoreLocation."
    }

    # Step 5: Export the certificate to a PFX file
    $CertFile = Join-Path $CertPath $CertPfxExportFileName
    Write-Log -message "Exporting certificate to PFX file: $CertFile"

    Export-PfxCertificate -Cert $cert `
        -FilePath $CertFile `
        -Password (ConvertTo-SecureString -String $CertPass -AsPlainText -Force)

    Write-Log -message "Certificate exported successfully to: $CertFile"

    # Step 6: Export the public certificate to a .pem file (for Ansible Container)
    $CertPemFile = Join-Path $CertPath "$CertPemExportFileName"
    Write-Log -message "Exporting the certificate to PEM file: $CertPemFile"

    # Export the public certificate to PEM format
    Set-Content -Path $CertPemFile -Value @(
        "-----BEGIN CERTIFICATE-----"
        [Convert]::ToBase64String($cert.RawData) -replace ".{64}", "$&`n"
        "-----END CERTIFICATE-----"
    )

    Write-Log -message "Certificate exported successfully to PEM file: $CertPemFile"

    # Step 7: Import the certificate into the Trusted Root Certification Authorities store
    Write-Log -message "Importing certificate into Trusted Root Certification Authorities store..."

    Import-PfxCertificate -FilePath $CertFile `
        -CertStoreLocation $TrustedRootStoreLocation `
        -Password (ConvertTo-SecureString -String $CertPass -AsPlainText -Force)

    Write-Log -message "Certificate imported successfully into Trusted Root store."

    # Step 8: Verify the installation by listing certificates in the Trusted Root store
    Write-Log -message "Verifying certificate installation in Trusted Root store..."

    # Step 8: Check if certificate with CN exists in the Trusted Root store
    $installedCert = Get-ChildItem -Path $TrustedRootStoreLocation `
        | Where-Object { $_.Subject -match "CN=$CertCN" }

    if (-not $installedCert) {
        Handle-Error -errorMessage "Certificate not found in Trusted Root store."
    }

    Write-Log -message "Certificate successfully installed and verified in Trusted Root store."
} catch {
    Handle-Error -errorMessage "An error occurred: $_"
}
