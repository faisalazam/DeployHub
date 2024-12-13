<#
    .SYNOPSIS
    This script rolls back the creation of a service account and removes it from a specified group.

    .DESCRIPTION
    The script checks if the user exists. If so, it removes the user from the specified group and deletes the user account.

    .PARAMETER UserName
    The name of the service account to be removed.

    .PARAMETER GroupName
    The name of the group from which the user will be removed.

    .EXAMPLE
    PS C:\> .\RollbackAnsibleUser.ps1
    Rolls back the creation of the service account 'ansible-agent' and removes it from the 'Remote Desktop Users' group.

    .NOTES
    Author: M. Faisal
#>

# Variables for the service account
param(
    [string]$UserName = "ansible-agent",
    [string]$GroupName = "Administrators"  # Or 'Administrators' if you need admin access
)

function Write-Log
{
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $message"
}

# Log the start of the rollback process
Write-Log "Starting the rollback process for the service account '$UserName'."

# Check if the user exists
Write-Log "Checking if user '$UserName' exists..."
$userExists = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue

if ($userExists)
{
    Write-Log "User '$UserName' exists. Proceeding with removal."

    # Remove the user from the group if they are a member
    Write-Log "Checking if '$UserName' is a member of the '$GroupName' group..."
    $userInGroup = Get-LocalGroupMember -Group $GroupName | Where-Object { $_.Name.Split('\')[-1] -eq $UserName }

    if ($userInGroup)
    {
        Write-Log "User '$UserName' is a member of the '$GroupName' group. Removing from group..."
        Remove-LocalGroupMember -Group $GroupName -Member $UserName
        if ($?)
        {
            Write-Log "User '$UserName' removed from the '$GroupName' group successfully."
        }
        else
        {
            Write-Log "Failed to remove '$UserName' from the '$GroupName' group. Error: $($Error[0].ToString())"
            exit 1  # Exit if removal from group failed
        }
    }
    else
    {
        Write-Log "User '$UserName' is not a member of the '$GroupName' group. Skipping group removal."
    }

    # Delete the user account
    Write-Log "Deleting user '$UserName'..."
    Remove-LocalUser -Name $UserName
    if ($?)
    {
        Write-Log "User '$UserName' deleted successfully."
    }
    else
    {
        Write-Log "Failed to delete user '$UserName'. Error: $($Error[0].ToString())"
        exit 1  # Exit if user deletion failed
    }
}
else
{
    Write-Log "User '$UserName' does not exist. No action needed."
}

# Output the final status
Write-Log "Rollback process complete for '$UserName'."

exit 0
