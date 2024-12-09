<#
    .SYNOPSIS
    This script creates a service account on Windows and adds it to a specified group (e.g., 'Remote Desktop Users').

    .DESCRIPTION
    The script checks if a user with the given name exists. If not, it creates the user with the specified password,
    full name, and description. It then ensures the user is added to the specified group.

    .PARAMETER UserName
    The name of the service account to be created.

    .PARAMETER Password
    The password for the service account.

    .PARAMETER FullName
    The full name for the service account.

    .PARAMETER Description
    A description for the service account.

    .PARAMETER GroupName
    The name of the group to which the user will be added (e.g., 'Remote Desktop Users').

    .EXAMPLE
    PS C:\> .\CreateAnsibleUser.ps1
    Creates a service account 'ANSIBLE_USER' and adds it to the 'Remote Desktop Users' group.

    .NOTES
    Author: M. Faisal
#>

# Variables for the service account
param(
    [string]$UserName = "ANSIBLE_USER",
    [string]$Password = "ANS1BLE_P@sS!", # Ideally, get this from a secure source
    [string]$FullName = "Ansible Service Account",
    [string]$Description = "Service account for Ansible",
    [string]$GroupName = "Remote Management Users"  # Or 'Administrators' if you need admin access
)

function Write-Log
{
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $machineName = $env:COMPUTERNAME
    Write-Host "[$timestamp] [$machineName] $message"
}

# Log the start of account creation process
Write-Log "Starting the process to create the service account '$UserName'."

# Check if the user already exists
Write-Log "Checking if user '$UserName' already exists..."
$userExists = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue

if ($userExists)
{
    Write-Log "User '$UserName' already exists. Skipping user creation."
}
else
{
    # Create the new user account
    Write-Log "Creating new user '$UserName'..."
    New-LocalUser -Name $UserName -Password (ConvertTo-SecureString -String $Password -AsPlainText -Force) -FullName $FullName -Description $Description
    if ($?)
    {
        Write-Log "User '$UserName' created successfully."
    }
    else
    {
        Write-Log "Failed to create user '$UserName'. Error: $($Error[0].ToString() )"
        exit 1  # Exit if user creation failed
    }
}

# Now, proceed to add the user to the group only if user creation was successful
Write-Log "Checking if '$UserName' is already in the '$GroupName' group..."

# Get all members of the group and check if the user exists
$userInGroup = Get-LocalGroupMember -Group $GroupName | Where-Object { $_.Name -eq $UserName -or $_.PrincipalSource -eq 'Local' }

if ($userInGroup) {
    Write-Log "User '$UserName' is already a member of the '$GroupName' group. Skipping group addition."
}
else
{
    # Add the user to the specified group
    Write-Log "Adding '$UserName' to the '$GroupName' group..."
    Add-LocalGroupMember -Group $GroupName -Member $UserName
    if ($?)
    {
        Write-Log "User '$UserName' added to the '$GroupName' group successfully."
    }
    else
    {
        Write-Log "Failed to add '$UserName' to the '$GroupName' group. Error: $($Error[0].ToString() )"
        exit 1  # Exit if adding to group failed
    }
}

# Output the final status
Write-Log "Ansible service account ('$UserName') creation and configuration process completed."
Write-Log "Account '$UserName' added to the '$GroupName' group."
Write-Log "Service account setup is complete."

exit 0