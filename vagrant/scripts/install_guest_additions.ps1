# Accept arguments for ISO path and Guest Additions executable
param (
    [string]$isoPath = "C:\VBoxGuestAdditions.iso",  # Default path to the ISO file
    [string]$guestAdditionsExecutable = "VBoxWindowsAdditions.exe"  # Default executable name
)

# Mount the disk image
Write-Host "Mounting the disk image: $isoPath"
Mount-DiskImage -ImagePath $isoPath -PassThru

# Allow time for the disk to initialize
Start-Sleep -Seconds 2

# Get the mounted drive
$volume = Get-Volume | Where-Object { $_.DriveType -eq "CD-ROM" } | Select-Object -First 1

if ($volume -and $volume.DriveLetter)
{
    $driveLetter = $volume.DriveLetter
    Write-Host "The ISO was mounted at drive: ${driveLetter}:"

    # Check for the Guest Additions executable
    if (Test-Path "${driveLetter}:\$guestAdditionsExecutable")
    {
        Write-Host "[INFO] Starting Guest Additions installation..."
        Start-Process "${driveLetter}:\$guestAdditionsExecutable" -ArgumentList "/S" -NoNewWindow -Wait
        Write-Host "[INFO] Guest Additions installed."
    }
    else
    {
        Write-Host "[ERROR] Guest Additions executable not found on the mounted ISO."
    }
}
else
{
    Write-Host "[ERROR] The ISO was mounted, but no drive letter was assigned or found."
}

# Dismount the disk image
Write-Host "Dismounting the disk image..."
Dismount-DiskImage -ImagePath $isoPath
Write-Host "[INFO] Disk image dismounted."

# Verify the Guest Additions version
VBoxControl.exe --version
