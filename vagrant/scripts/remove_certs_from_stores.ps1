param (
    [Parameter(Mandatory=$true)]
    [string]$FriendlyNamePattern
)

$storeLocations = @(
    "Cert:\LocalMachine\Root",
    "Cert:\LocalMachine\My",
    "Cert:\LocalMachine\CA",
    "Cert:\LocalMachine\AuthRoot",
    "Cert:\LocalMachine\Trust"
)

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
        -logLevel "INFO"

    try {
        # Get all certificates from the store
        $certs = Get-ChildItem -Path $storeLocation | Where-Object { `
            $_.FriendlyName -like $friendlyNamePattern `
        }

        if ($null -eq $certs -or $certs.Count -eq 0) {
            Write-Log -message "No certificates found in '$storeLocation' matching '$friendlyNamePattern'" `
                -logLevel "INFO"
            return
        }

        foreach ($cert in $certs) {
            Write-Log -message "Removing certificate: $($cert.FriendlyName) " `
                + "(Thumbprint: $($cert.Thumbprint)) from store $storeLocation..."
            Remove-Item -Path $cert.PSPath -Force
            Write-Log -message "Certificate removed: $($cert.FriendlyName) " `
                + "(Thumbprint: $($cert.Thumbprint))"
        }
    } catch {
        Write-Log -message "An error occurred while removing certificates: $_" `
            -logLevel "ERROR"
    }
}

foreach ($storeLocation in $storeLocations) {
    Remove-CertsByFriendlyName -storeLocation $storeLocation `
        -friendlyNamePattern $FriendlyNamePattern
}
