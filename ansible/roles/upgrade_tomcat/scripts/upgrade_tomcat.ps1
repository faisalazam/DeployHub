## Example:
## script files and the zip should coexist in the same folder, let's say: `tomcat-upgrade-utility`.
## cd in to the script dir, i.e. `tomcat-upgrade-utility`
##
## Ensure that there is exactly one jar file in "lib\elastic" of the current tomcat\srva dir,
## or else delete the ones which are not required:
#ls D:\tomcat\srva\lib\elastic\elastic-apm-agent-*.jar
#
## Run the following command by adjusting the params to get ready for the upgrade.
## It'll prepare the srva folder containing all the files required for the upgrade.
#$upgradedServiceName = $(.\prepare_tomcat_upgrade.ps1 `
#    -tomcatInstallationDrive "C:" `
#    -tomcatZipPath ".\apache-tomcat-9.0.98-windows-x64.zip")
#
## Run the Following to list down the currently installed Tomcat services and note down the servie names:
#Get-Service |
#        Where-Object { $_.DisplayName -like "*Tomcat*" -or $_.Name -like "*Tomcat*" } |
#        Select-Object Status, Name, DisplayName, @{Name="StartupType";Expression={(Get-WmiObject -Class Win32_Service -Filter "Name='$($_.Name)'").StartMode}} |
#        Format-Table -AutoSize
#
## Open the properties dialog by running the following command:
#D:\tomcat\srva\bin\TOMCAT99664_SRVA.exe # where TOMCAT99664_SRVA.exe => ${currentServiceToUpgrade}.exe
#
## Once open, click on `Log On` tab, copy and note down the username, this is the value for the `tomcatLogOnUsername` param.
## Then click on the `Java` tab, copy and note down the JVM dll path,
## e.g. `D:\java\jre8.0.412-x64zulu\bin\server\jvm.dll`, this is the value for the `jvmDLLPath` param.
#
## Then go to Bitwarden to get the password for the username which was retrieved in the last step.
## Update the password in the following command and run:
#$SecurePassword = ConvertTo-SecureString "PASSWORD_FROM_BITWARDEN" -AsPlainText -Force
#
## Ensure that no File Explorer is open to avoid access denied sort of issues for the current tomcat folder.
## Finally, adjust the params in the following command and then run to perform the upgrade:
## NOTE: The `maxMemoryPool` and `initialMemoryPool` params are optional. If you don't provide them explicitly,
## then `4096` and `256` values will be used by default for them respectively.
## Check if custom jre path is required. If yes, then, use the $jvmDLLPath param.
## The $jvmDLLPath is also optional, and if provided, ensure that it is the full jvm.dll path:
## e.g. "D:\java\jre8.0.412-x64zulu\bin\server\jvm.dll"
## Next, the `tomcatLogOnPassword` and `tomcatLogOnUsername` are mandatory only if the `setupLogOnCreds` param is set `$true`.
## For further parameterisation: https://tomcat.apache.org/tomcat-9.0-doc/windows-service-howto.html
#.\upgrade_tomcat.ps1 `
#    -maxMemoryPool "4096" `
#    -initialMemoryPool "256" `
#    -jvmDLLPath "D:\java\jre8.0.412-x64zulu\bin\server\jvm.dll" `
#    -serviceToUninstall "TOMCAT99364_SRVA" `
#    -currentServiceToUpgrade "TOMCAT99664_SRVA" `
#    -upgradedServiceName "$upgradedServiceName" `
#    -setupLogOnCreds $true `
#    -tomcatInstallationDrive "C:" `
#    -tomcatLogOnPassword $SecurePassword `
#    -tomcatLogOnUsername "octaneautest\svc_tomcat_benzine"

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

function Write-Log {
    param(
        [string]$message,
        [string]$type = "INFO"
    )
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$type] $message"

    $logColors = @{
        "INFO"  = "Green"
        "WARN"  = "Yellow"
        "ERROR" = "Red"
        "DEBUG" = "Cyan"
        "FATAL" = "Magenta"
    }

    $logColor = $logColors[$type]
    if (-not $logColor) {
        $logColor = "White"
    }
    Write-Host $logMessage -ForegroundColor $logColor
}

function Stop-SpecifiedService {
    param(
        [string]$serviceName
    )

    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($null -eq $service) {
        Write-Log "Service '$serviceName' not found." "ERROR"
        exit 1
    }

    if ($service.Status -eq 'Running') {
        Write-Log "Stopping the '$serviceName' service..."
        try {
            Stop-Service -Name $serviceName -Force
            Write-Log "The '$serviceName' service stopped successfully."
        } catch {
            Write-Log "Failed to stop service '$serviceName'. Error: $_" "ERROR"
            exit 1
        }
    } else {
        Write-Log "The '$serviceName' service is not running."
    }
}

function Start-SpecifiedService {
    param(
        [string]$serviceName
    )

    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service.Status -eq 'Running') {
        Write-Log "The '$serviceName' service is already running."
    } else {
        Write-Log "Starting the '$serviceName' service..."
        try {
            Start-Service -Name $serviceName
            Start-Sleep -Seconds 5
            $serviceStatus = Get-Service -Name $serviceName
            if ($serviceStatus.Status -eq 'Running') {
                Write-Log "The '$serviceName' service started successfully."
            } else {
                Write-Log "Failed to start the '$serviceName' service. Status: $($serviceStatus.Status)" "ERROR"
                exit 1
            }
        } catch {
            Write-Log "Failed to start service '$serviceName'. Error: $_" "ERROR"
            exit 1
        }
    }
}

function Set-ServiceStartMode {
    param (
        [string]$serviceName,
        [string]$startMode,  # Accepts 'Automatic', 'Manual', or 'Disabled'
        [string]$logMessage  # Optional custom log message for context
    )

    if (-not $serviceName) {
        Write-Log "Service name is required." "ERROR"
        return
    }

    if ($startMode -notin @('Automatic', 'Manual', 'Disabled')) {
        Write-Log "Invalid start mode specified. Please choose from 'Automatic', 'Manual', or 'Disabled'." "ERROR"
        return
    }

    try {
        $service = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"
        if ($null -eq $service) {
            Write-Log "Service '$serviceName' not found." "ERROR"
            return
        }

        $service.ChangeStartMode($startMode)
        Write-Log "Successfully set the start mode of service '$serviceName' to '$startMode'. $logMessage"
    } catch {
        Write-Log "An error occurred while changing the start mode of service '$serviceName'. Details: $($_.Exception.Message)" "ERROR"
    }
}

function Set-TomcatServiceLogon {
    param (
        [string]$serviceName,
        [string]$username,
        [string]$tomcatExeFile,
        [SecureString]$password,
        [string]$setupLogOnCreds
    )
    if ($setupLogOnCreds -eq $false) {
        $username = "LocalSystem"
    }

    $servicePasswordArg = @()
    if ($password -ne $null) {
        $PlainTextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
        $servicePasswordArg += "--ServicePassword=`"$PlainTextPassword`""
    }

    try {
        & "$tomcatExeFile" //US//$serviceName --ServiceUser="$username" @servicePasswordArg -ErrorAction Stop
        Write-Log "Successfully set logon credentials for $serviceName to $username"
    } catch {
        Write-Log "An error occurred while setting the logon credentials for ${serviceName}: $_" "ERROR"
    }
}

function Set-ElasticJavaAgent {
    param (
        [string]$serviceName,
        [string]$tomcatExeFile,
        [string]$currentSrvaDir
    )

    try {
        $elasticAgentDir = Join-Path -Path $currentSrvaDir -ChildPath  "lib\elastic"
        $elasticAgentJars = Get-ChildItem -Path $elasticAgentDir -Filter "elastic-apm-agent-*.jar"
        if ($elasticAgentJars.Count -eq 1) {
            $jarPath = $elasticAgentJars.FullName
            & "$tomcatExeFile" "//US//$serviceName" ++JvmOptions="-javaagent:$jarPath" -ErrorAction Stop
            Write-Log "Successfully set elastic javaagent on $serviceName"
        } else {
            Write-Log "No elastic-apm-agent jar file found in $elasticAgentDir, or there are multiple such files." "WARN"
        }
    } catch {
        Write-Log "An error occurred while setting the elastic javaagent for ${serviceName}: $_" "ERROR"
    }
}

function Remove-SpecifiedItem {
    param (
        [string]$itemPath
    )

    try {
        if (Test-Path $itemPath) {
            Remove-Item -Path $itemPath -Recurse -Force
            Write-Log "Successfully removed: $itemPath"
        } else {
            Write-Log "Item not found: $itemPath"
        }
    } catch {
        Write-Log "Failed to remove item '$itemPath'. Error: $_" "ERROR"
        exit 1
    }
}

function Manage-TomcatService {
    param (
        [string]$srvaDirName,
        [string]$serviceName,
        [ValidateSet("Install", "Uninstall")]
        [string]$action
    )

    $serviceBatPath = Join-Path -Path $srvaDirName -ChildPath "bin\service.bat"
    if (-Not (Test-Path $serviceBatPath)) {
        Write-Log "The service.bat not found at $serviceBatPath" "ERROR"
        exit 1
    }

    $cmdAction = $action.ToLower()  # "install" or "uninstall"
    $existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($cmdAction -eq "install" -and $existingService) {
        Write-Log "The service '$serviceName' already exists. Skipping installation." "WARN"
        return $false
    }
    if ($cmdAction -eq "uninstall" -and -not $existingService) {
        Write-Log "The service '$serviceName' does not exist. Skipping uninstallation." "WARN"
        return $false
    }

    try {
        $originalDir = Get-Location

        # Change to the directory containing the batch file
        Set-Location -Path (Split-Path -Path $serviceBatPath)

        & cmd.exe /c "service.bat $cmdAction $serviceName"
        $exitCode = $LASTEXITCODE

        # Restore the original working directory
        Set-Location -Path $originalDir

        if ($exitCode -eq 0) {
            Write-Log "Successfully executed 'service.bat $cmdAction' for service '$serviceName'."
            return $true;
        } else {
            Write-Log "'service.bat $cmdAction' failed with exit code $exitCode" "ERROR"
        }
    } catch {
        Write-Log "An error occurred while executing 'service.bat $cmdAction': $_" "ERROR"
        Set-Location -Path $originalDir
    }
}

function Log-ExampleScript {
    Write-Host "###################################   Example Start   ##########################################"
    Write-Host "Run the following to list down the Tomcat services: "
    Write-Host @'
$upgradedServiceName = $(.\prepare_tomcat_upgrade.ps1 `
    -tomcatInstallationDrive "D:" `
    -tomcatZipPath ".\apache-tomcat-9.0.98-windows-x64.zip")
'@
    Write-Host "###################################   Example End     ##########################################"
}

function Test-DirectoryAccessibility {
    param (
        [string]$directoryPath
    )
    # Verify if the directory exists
    if (-not (Test-Path -Path $directoryPath -PathType Container)) {
        Write-Log "Directory does not exist: $directoryPath" "ERROR"
        return $false
    }

    # Check if any files in the directory are locked by running processes
    $lockedFiles = Get-Process | Where-Object {
        $_.Modules | Where-Object { $_.FileName -like "$directoryPath\*" }
    }

    if ($lockedFiles) {
        Write-Log "The folder $directoryPath is locked by running processes: $lockedFiles" "ERROR"
        Write-Log "Ensure the running processes are stopped before attempting again." "ERROR"
        return $false
    }

    return $true
}

function Validate-OptionalParameters {
    param (
        [bool]$setupLogOnCreds,
        [string]$tomcatLogOnUsername,
        [SecureString]$tomcatLogOnPassword
    )

    if ($setupLogOnCreds -eq $true) {
        $missingParams = @()
        if (-not $tomcatLogOnUsername) { $missingParams += "tomcatLogOnUsername" }
        if (-not $tomcatLogOnPassword -or $tomcatLogOnPassword.Length -eq 0) { $missingParams += "tomcatLogOnPassword" }
        if ($missingParams.Count -gt 0) {
            Write-Log "Missing required parameters: $($missingParams -join ', ') when setupLogOnCreds is true." "ERROR"
            exit 1
        }
    }
}

$stepCounter = -1
$srvDirName = "srva"
$tomcatDirName = "tomcat"
$rollbackRequired = $true
$newServiceStarted = $false
$backupDirPass = "1234567890"
$currentTomcatDir = Join-Path -Path $tomcatInstallationDrive -ChildPath $tomcatDirName
$currentSrvaDir = Join-Path -Path $currentTomcatDir -ChildPath $srvDirName
$tomcatExeFile = Join-Path -Path $currentSrvaDir -ChildPath  "bin\tomcat9.exe"
$currentSrvaBackupDir = Join-Path -Path $currentTomcatDir -ChildPath "${currentServiceToUpgrade}_old"

# Stop the old service and install and start the new service by backing up the old tomcat and copying over the new tomcat folder
try {
    Write-Log "Step $((++$stepCounter)): Test that the '$tomcatDirName' folder exists."
    if (-not (Test-Path $tomcatDirName)) {
        Write-Log "The specified $tomcatDirName folder does not exist. Did you forget to run the preparation script?" "ERROR"
        Log-ExampleScript
        exit 1
    }

    Write-Log "Step $((++$stepCounter)): Validate optional params"
    Validate-OptionalParameters -setupLogOnCreds $setupLogOnCreds -tomcatLogOnUsername $tomcatLogOnUsername -tomcatLogOnPassword $tomcatLogOnPassword

    Write-Log "Step $((++$stepCounter)): Stop the '$currentServiceToUpgrade' service"
    Stop-SpecifiedService -serviceName $currentServiceToUpgrade -ErrorAction Stop

    Write-Log "Starting folder management steps..."
    try {
        Write-Log "Step $((++$stepCounter)): Closing the File Explorer process to release folder lock."
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

        Write-Log "Step $((++$stepCounter)): Closing the Services (i.e. mmc.exe if running) to release folder lock."
        Stop-Process -Name mmc -Force -ErrorAction SilentlyContinue

        Write-Log "Step $((++$stepCounter)): Test that the '$currentSrvaDir' folder is accessible."
        if (-not (Test-DirectoryAccessibility -directoryPath "$currentSrvaDir")) {
            Write-Log "Directory is not accessible, skipping folder management steps." "ERROR"
            throw "Directory not accessible"
        }

        Write-Log "Step $((++$stepCounter)): Rename the $currentSrvaDir folder to $currentSrvaBackupDir"
        Move-Item -Path $currentSrvaDir -Destination $currentSrvaBackupDir -Force -ErrorAction Stop
        $srvaRenamed = $true

        Write-Log "Step $((++$stepCounter)): Move the $tomcatDirName\* folder to $currentTomcatDir\*"
        Move-Item -Path "$tomcatDirName\*" -Destination "$currentTomcatDir" -Force -ErrorAction Stop
        $tomcatMoved = $true

        Write-Log "Folder management completed successfully."
    } catch {
        Write-Log "Error during folder management: $($_.Exception.Message)" "ERROR"
        throw
    }

    Write-Log "Starting service management steps..."
    try {
        Write-Log "Step $((++$stepCounter)): Install as Windows Service by running cmd inside $currentSrvaDir\bin"
        $didItInstallTheService = Manage-TomcatService -action "Install" -srvaDirName $currentSrvaDir -serviceName $upgradedServiceName -ErrorAction Stop
        $serviceInstalled = $true

        if ($didItInstallTheService -eq $true) {
            Write-Log "Step $( (++$stepCounter) ): Modify $srvDirName\bin\${upgradedServiceName}.exe with the Log On credentials"
            Set-TomcatServiceLogon -tomcatExeFile $tomcatExeFile -serviceName $upgradedServiceName -setupLogOnCreds $setupLogOnCreds -username $tomcatLogOnUsername -password $tomcatLogOnPassword -ErrorAction Stop

            Write-Log "Step $( (++$stepCounter) ): Modify $srvDirName\bin\${upgradedServiceName}.exe with elastic JavaAgent"
            Set-ElasticJavaAgent -tomcatExeFile $tomcatExeFile -serviceName $upgradedServiceName -currentSrvaDir $currentSrvaDir -ErrorAction Stop

            Write-Log "Step $( (++$stepCounter) ): Modify $srvDirName\bin\${upgradedServiceName}.exe to blank out the JvmOptions9"
            # This step needs to be removed once we start using Java 9 or later
            & "$tomcatExeFile" "//US//$serviceName" --JvmOptions9="" -ErrorAction Stop

            Write-Log "Step $( (++$stepCounter) ): Modify $srvDirName\bin\${upgradedServiceName}.exe to redirect logs to nothing"
            & "$tomcatExeFile" //US//$upgradedServiceName --StdOutput="" --StdError="" -ErrorAction Stop

            Write-Log "Step $( (++$stepCounter) ): Modify $srvDirName\bin\${upgradedServiceName}.exe to set initial and max memory pool size"
            & "$tomcatExeFile" //US//$upgradedServiceName --JvmMs="$initialMemoryPool" --JvmMx="$maxMemoryPool" -ErrorAction Stop

            if ($jvmDLLPath) {
                Write-Log "Step $( (++$stepCounter) ): Modify $srvDirName\bin\${upgradedServiceName}.exe to set the jvm.dll"
                & "$tomcatExeFile" //US//$upgradedServiceName --Jvm="$jvmDLLPath" -ErrorAction Stop
                Write-Log "Executed Tomcat service update with JVM set to: $jvmDLLPath"
            } else {
                Write-Log "Skipping JVM configuration and using default, as the jvmDLLPath is not provided." "WARN"
            }
        }

        Write-Log "Step $((++$stepCounter)): Make the startup type of currently installed Tomcat Service to be Disabled."
        Set-ServiceStartMode -serviceName $currentServiceToUpgrade -startMode 'Disabled' -ErrorAction Stop
        $oldServiceDisabled = $true

        Write-Log "Step $((++$stepCounter)): Make the startup type of newly installed Tomcat Service to be Automatic."
        Set-ServiceStartMode -serviceName $upgradedServiceName -startMode 'Automatic' -ErrorAction Stop

        Write-Log "Step $((++$stepCounter)): Start the '$upgradedServiceName' service"
        Start-SpecifiedService -serviceName $upgradedServiceName -ErrorAction Stop
        $newServiceStarted = $true

        Write-Log "Service upgrade completed successfully."
        Write-Log "MANUAL STEP => PROD - DO NOT FORGET TO UPDATE LOAD BALANCER DEPLOYMENT SCRIPT."
    } catch {
        Write-Log "Error during service management: $($_.Exception.Message)" "ERROR"
        throw
    }

    $rollbackRequired = $false
} catch {
    Write-Log "An error occurred during the upgrade process: $($_.Exception.Message)" "ERROR"

    if ($rollbackRequired) {
        try {
            Write-Log "Starting rollback process..." "WARN"

            if ($newServiceStarted) {
                Write-Log "Stopping the newly installed service '$upgradedServiceName'..." "WARN"
                Stop-SpecifiedService -serviceName $upgradedServiceName -ErrorAction SilentlyContinue
            }

            if ($serviceInstalled) {
                Write-Log "Uninstalling the newly installed service '$upgradedServiceName'..." "WARN"
                Manage-TomcatService -action "Uninstall" -srvaDirName $currentSrvaDir -serviceName $upgradedServiceName -ErrorAction SilentlyContinue
            }

            if ($oldServiceDisabled) {
                Write-Log "Restoring startup mode of '$currentServiceToUpgrade' to Automatic." "WARN"
                Set-ServiceStartMode -serviceName $currentServiceToUpgrade -startMode 'Automatic' -ErrorAction SilentlyContinue
            }

            # Rollback folder changes
            if ($tomcatMoved) {
                Write-Log "Rolling back move: Restoring contents of $tomcatDirName back to $currentTomcatDir" "WARN"
                Move-Item -Path "$currentTomcatDir\*" -Destination "$tomcatDirName" -Force -ErrorAction Stop
            }

            if ($srvaRenamed) {
                Write-Log "Rolling back rename: Restoring $currentSrvaBackupDir to $currentSrvaDir" "WARN"
                Move-Item -Path $currentSrvaBackupDir -Destination $currentSrvaDir -Force -ErrorAction Stop
            }

            Write-Log "Restarting the original service '$currentServiceToUpgrade'..." "WARN"
            Start-SpecifiedService -serviceName $currentServiceToUpgrade -ErrorAction SilentlyContinue

            Write-Log "Rollback completed successfully." "WARN"
        } catch {
            Write-Log "Rollback failed. Manual intervention needed: $($_.Exception.Message)" "ERROR"
            throw
        }
    }
} finally {
    Write-Log "Step $((++$stepCounter)): Current status of the Tomcat services before the cleanup"
    Get-Service |
            Where-Object { $_.DisplayName -like "*Tomcat*" -or $_.Name -like "*Tomcat*" } |
            Select-Object Status, Name, DisplayName, @{ Name = "StartupType"; Expression = { (Get-WmiObject -Class Win32_Service -Filter "Name='$($_.Name)'").StartMode } } |
            Format-Table -AutoSize
}

if ($newServiceStarted) {
    Write-Log "Starting final cleanup steps..."
    try {
        if ($serviceToUninstall) {
            Write-Log "Step $((++$stepCounter)): Uninstall the old Service by running cmd inside $currentSrvaDir\bin"
            Manage-TomcatService -action "Uninstall" -srvaDirName $currentSrvaDir -serviceName $serviceToUninstall -ErrorAction Stop
        } else {
            Write-Log "Skipping the uninstall of the old service, as the serviceToUninstall is not provided." "WARN"
        }

        Write-Log "Step $((++$stepCounter)): Password protect the $currentSrvaBackupDir backup dir"
        & "C:\Program Files\7-Zip\7z.exe" a -p"$backupDirPass" -m0=Copy -tzip "$currentSrvaBackupDir.zip" "$currentSrvaBackupDir\*" -r

        Write-Log "Step $((++$stepCounter)): Remove the $currentSrvaBackupDir folder"
        Remove-SpecifiedItem -itemPath $currentSrvaBackupDir -ErrorAction Stop

        # TODO: Also add a step to remove the old zip?
        Write-Log "Cleanup completed successfully."
    } catch {
        Write-Log "Error during final cleanup: $($_.Exception.Message)" "ERROR"
        throw
    }
} else {
    Write-Log "New service did not start. Skipping cleanup steps." "WARN"
}
