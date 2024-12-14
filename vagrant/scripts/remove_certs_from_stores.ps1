param (
    [string]$FriendlyNamePattern = "SETTING IT ANY RANDOM STR SO THAT NOTHING GETS UNTIL PATTERN IS PROVIDED"
)

# Define certificate store locations
$personalStoreLocation = "Cert:\LocalMachine\My"
$trustedRootStoreLocation = "Cert:\LocalMachine\Root"

function Write-Log {
    param (
        [string]$message,
        [string]$logLevel = "INFO"
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "$timestamp [$logLevel] $message"
}

function Remove-CertsByFriendlyName {
    param (
        [string]$storeLocation,
        [string]$friendlyNamePattern
    )

    Write-Log -message "Removing certificates with FriendlyName matching '$friendlyNamePattern' " `
        -logLevel "INFO" `

    try {
        # Get all certificates from the store
        $certs = Get-ChildItem -Path $storeLocation | Where-Object { `
            $_.FriendlyName -like $friendlyNamePattern `
        }

        if ($certs.Count -eq 0) {
            Write-Log -message "No certificates found matching '$friendlyNamePattern' " `
                -logLevel "INFO"
            return
        }

        foreach ($cert in $certs) {
            Write-Log -message "Removing certificate: $($cert.FriendlyName) " `
                + "(Thumbprint: $($cert.Thumbprint)) from store $storeLocation..."
            # Remove the certificate
            Remove-Item -Path $cert.PSPath -Force
            Write-Log -message "Certificate removed: $($cert.FriendlyName) " `
                + "(Thumbprint: $($cert.Thumbprint))"
        }
    } catch {
        Write-Log -message "An error occurred while removing certificates: $_" `
            -logLevel "ERROR"
    }
}

# Remove certificates from the 'My' store (Personal certificates)
Remove-CertsByFriendlyName -storeLocation $personalStoreLocation `
    -friendlyNamePattern $FriendlyNamePattern

# Remove certificates from the 'Root' store (Trusted Root Certification Authorities)
Remove-CertsByFriendlyName -storeLocation $trustedRootStoreLocation `
    -friendlyNamePattern $FriendlyNamePattern
