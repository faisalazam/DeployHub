param(
    [Parameter(Mandatory=$true)]
    [string]$upgradedServiceName,

    [Parameter(Mandatory=$true)]
    [string]$currentServiceToUpgrade,

    [Parameter(Mandatory=$true)]
    [string]$tomcatInstallationDrive,

    [Parameter(Mandatory=$true)]
    [boolean]$setupLogOnCreds,

    [string]$jvmDLLPath,
    [string]$serviceToUninstall,
    [string]$tomcatLogOnUsername,
    [string]$maxMemoryPool = "4096",
    [string]$initialMemoryPool = "256",
    [SecureString]$tomcatLogOnPassword
)

Write-Host "Current Directory: $(Get-Location)"
Write-Host "upgradedServiceName: $upgradedServiceName"
Write-Host "currentServiceToUpgrade: $currentServiceToUpgrade"
Write-Host "tomcatInstallationDrive: $tomcatInstallationDrive"
Write-Host "setupLogOnCreds: $setupLogOnCreds"
Write-Host "jvmDLLPath: $jvmDLLPath"
Write-Host "serviceToUninstall: $serviceToUninstall"
Write-Host "tomcatLogOnUsername: $tomcatLogOnUsername"
Write-Host "maxMemoryPool: $maxMemoryPool"
Write-Host "initialMemoryPool: $initialMemoryPool"
Write-Host "tomcatLogOnPassword: $tomcatLogOnPassword"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Shell is not run as Administrator..."
} else {
    Write-Host "Shell is running as Administrator..."
}