# Example:
# .\prepare_tomcat_upgrade.ps1 -tomcatInstallationDrive "D:" -tomcatZipPath ".\apache-tomcat-9.0.98-windows-x64.zip"

param(
    [Parameter(Mandatory=$true)]
    [string]$tomcatInstallationDrive,

    [Parameter(Mandatory=$true)]
    [string]$tomcatZipPath,

    [Parameter(Mandatory=$true)]
    [string]$upgradedServiceName
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

function Expand-Tomcat {
    param(
        [string]$zipFilePath,
        [string]$folderName
    )

    if (-Not (Test-Path $zipFilePath)) {
        Write-Log "Tomcat zip file not found at '$zipFilePath'." "ERROR"
        exit 1
    }

    $destinationFolder = Get-Location # Current Dir location
    $newFolderName = Join-Path -Path $destinationFolder -ChildPath $folderName
    if (Test-Path $newFolderName) {
        Write-Log "Target folder '$newFolderName' already exists. Deleting it..."
        Remove-SpecifiedItem -itemPath $newFolderName
    }

    try {
        Write-Log "Unzipping Tomcat files from '$zipFilePath' to '$newFolderName'..."
        Expand-Archive -Path $zipFilePath -DestinationPath $newFolderName -Force
        $zipRootFolderInsideDestFolder = Get-Item "$folderName\*" # this will pick up the apache-tomcat-* folder inside the $folderName folder.
        Move-Item -Path "$zipRootFolderInsideDestFolder\*" -Destination "$folderName" -Force
        Remove-SpecifiedItem -itemPath $zipRootFolderInsideDestFolder
        Write-Log "Tomcat zip file extracted successfully."
    } catch {
        Write-Log "Failed to unzip Tomcat files. Error: $_" "ERROR"
        exit 1
    }
}

function Backup-File {
    param(
        [string]$filePath
    )

    if (-Not (Test-Path $filePath)) {
        Write-Log "File not found: $filePath" "WARN"
        return
    }

    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
    $fileExtension = [System.IO.Path]::GetExtension($filePath)
    $backupFileName = "${fileNameWithoutExtension}_bkp$fileExtension"

    try {
        Rename-Item -Path $filePath -NewName $backupFileName -Force
        Write-Log "Successfully renamed $filePath to $backupFileName"
    } catch {
        Write-Log "Error renaming $filePath. Error: $_" "ERROR"
    }
}

function Copy-File {
    param (
        [string]$sourcePath,
        [string]$destinationPath
    )

    try {
        # If it's a directory, use Copy-Item with -Recurse
        if (Test-Path $sourcePath -PathType Container) {
            # Ensure destination directory exists
            if (!(Test-Path $destinationPath)) {
                New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
            }
            Copy-Item -Path "$sourcePath\*" -Destination $destinationPath -Recurse -Force
        } else {
            # Copy individual files
            Copy-Item -Path $sourcePath -Destination $destinationPath -Force
        }
        Write-Log "Copied: $sourcePath to $destinationPath"
    } catch {
        Write-Log "Failed to copy $sourcePath to $destinationPath. Error: $_" "ERROR"
    }
}

function Copy-TomcatFiles {
    param (
        [string]$currentSrvaDir,
        [string]$upgradedSrvaDirName
    )

    # File paths to copy
    $filePaths = @(
        "..\restart_tomcat.bat",
        "bin\sqljdbc_auth.dll",
        "logs",
        "conf\cert",
        "conf\catalina.properties",
        "conf\context.xml",
        "conf\server.xml",
        "lib\elastic",
        "lib\thirdparty",
        "lib\log4j2.properties",
        "webapps\ROOT\favicon.ico",
        "webapps\ROOT\index.html",
        "webapps\*.war"
    )

    foreach ($relativePath in $filePaths) {
        $sourcePath = Join-Path -Path $currentSrvaDir -ChildPath $relativePath
        if (Test-Path $sourcePath) {
            if ($relativePath -match '\*') {
                $parentDir = Split-Path -Parent $relativePath
                $destinationDir = Join-Path -Path $upgradedSrvaDirName -ChildPath $parentDir

                # Ensure destination directory exists
                if (!(Test-Path $destinationDir)) {
                    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
            }

                Get-ChildItem -Path $sourcePath | ForEach-Object {
                    $destinationPath = Join-Path -Path $destinationDir -ChildPath $_.Name
                    Copy-File -sourcePath $_.FullName -destinationPath $destinationPath
                }
            } else {
            $destinationPath = Join-Path -Path $upgradedSrvaDirName -ChildPath $relativePath
            Copy-File -sourcePath $sourcePath -destinationPath $destinationPath
            }
        } else {
            Write-Log "Source not found: $sourcePath" "WARN"
        }
    }
}

#function Get-VersionFromFilename {
#    param (
#        [string]$fileName
#    )
#
#    if ($fileName -match "(\d+(\.\d+)+)") {
#        $version = $matches[1]
#        $version = $version -replace '\.', '_'
#        return $version
#    } else {
#        Write-Log "No version found in the '$fileName' filename." "ERROR"
#    }
#}
#
#function Get-VersionSpecificFilename {
#    param (
#        [string]$zipFilePath
#    )
#
#    $version = Get-VersionFromFilename -fileName $zipFilePath
#    if ($version) {
#        if ($zipFilePath -match "x86") {
#            return "TOMCAT_${version}_32_SRVA"
#        } elseif ($zipFilePath -match "x64") {
#            return "TOMCAT_${version}_64_SRVA"
#        } else {
#            Write-Log "Could not determine architecture (x86/x64) from filename: $zipFilePath" "WARN"
#            return "TOMCAT_${version}_UNKNOWN_SRVA"
#        }
#    } else {
#        Write-Log "Version extraction failed." "ERROR"
#        exit 1
#    }
#}

function Copy-TomcatExecutable {
    param (
        [string]$newFileName,
        [string]$upgradedSrvaDirName
    )

    $sourceFile = Join-Path -Path $upgradedSrvaDirName -ChildPath "bin\tomcat9w.exe"
    if (Test-Path $sourceFile) {
        $destinationFile = Join-Path -Path $upgradedSrvaDirName -ChildPath "bin\${newFileName}.exe"
        Copy-Item -Path $sourceFile -Destination $destinationFile -Force
        Write-Log "Duplicated $sourceFile and renamed the file to $destinationFile"
    } else {
        Write-Log "Source file '$sourceFile' not found." "ERROR"
        exit 1
    }
}

function Read-FileContent {
    param (
        [string]$filePath
    )

    try {
        if (-Not (Test-Path $filePath)) {
            Write-Log "File not found at path $filePath" "ERROR"
            exit 1
        }

        $fileContent = Get-Content -Path $filePath -Raw
        return $fileContent
    } catch {
        Write-Log "Unable to read the file at $filePath. Ensure you have proper permissions." "ERROR"
        exit 1
    }
}

function InjectXmlTag {
    param (
        [string]$xmlContent,
        [string]$closingTag,
        [string]$contentToInject
    )

    if ($xmlContent -notmatch $closingTag) {
        Write-Log "Closing tag '$closingTag' not found. The XML file may be malformed." "ERROR"
        exit 1
    }

    try {
        # Insert the new content just before the closing tag
        $updatedContent = $xmlContent -replace "($closingTag)", "$contentToInject`n`$1"
        return $updatedContent
    } catch {
        Write-Log "Failed to inject content into the XML file. Verify the file's structure." "ERROR"
        exit 1
    }
}

function Save-ContentInFile {
    param (
        [string]$filePath,
        [string]$fileContent
    )

    try {
        Set-Content -Path $filePath -Value $fileContent
    } catch {
        Write-Log "Unable to save changes to $filePath. Ensure the file is writable." "ERROR"
        exit 1
    }
}

function Add-TomcatUserRolesAndUser {
    param (
        [string]$xmlFilePath
    )

    $roleAndUserStringToInject = @"
    <role rolename="manager-script"/>
    <role rolename="manager-gui"/>
    <user name="admin" password="t!@btom" roles="admin-gui,manager-gui,manager-script" />
"@

    $closingTag = '</tomcat-users>'
    Update-ContentInFile `
        -filePath $xmlFilePath `
        -regexPattern $closingTag `
        -replacementBlock "$roleAndUserStringToInject`n$closingTag" `
        -successMessage "Roles and user added successfully to $xmlFilePath" `
        -errorMessage "Closing tag '$closingTag' not found in the XML file. Cannot add roles and user."
}

function Add-StrictQuoteEscaping {
    param (
        [string]$xmlFilePath
    )

    $strictQuoteEscapingToInject = @"
    <init-param>
            <param-name>strictQuoteEscaping</param-name>
            <param-value>false</param-value>
        </init-param>
"@

    $servletPattern = '(?s)(<servlet>.*?</servlet>)'
    $xmlContent = Read-FileContent -filePath $xmlFilePath
    # First, extract all servlet blocks in the xml
    $servletBlocks = [regex]::Matches($xmlContent, $servletPattern) | ForEach-Object { $_.Groups[1].Value }
    $jspServletPattern = '<servlet-class>\s*org\.apache\.jasper\.servlet\.JspServlet\s*</servlet-class>'
    foreach ($servlet in $servletBlocks) {
        if ($servlet -match $jspServletPattern) {
            $updatedServlet = InjectXmlTag -xmlContent $servlet -closingTag '</servlet>' -contentToInject $strictQuoteEscapingToInject
            $updatedContent = $xmlContent -replace [regex]::Escape($servlet), $updatedServlet
            Save-ContentInFile -filePath $xmlFilePath -fileContent $updatedContent
            Write-Log "The 'strictQuoteEscaping' init-param injected successfully to $xmlFilePath"
            return  # Exit early since we only modify one block
        }
    }

    Write-Log "No <servlet> block with class 'org.apache.jasper.servlet.JspServlet' found." "ERROR"
    exit 1
}

function Update-ContentInFile {
    param (
        [string]$filePath,
        [string]$regexPattern,
        [string]$replacementBlock,
        [string]$successMessage,
        [string]$errorMessage
    )

    $fileContent = Read-FileContent -filePath $filePath
    try {
        if ($fileContent -notmatch $regexPattern) {
            Write-Log $errorMessage "ERROR"
            return
        }

        $updatedContent = $fileContent -replace $regexPattern, $replacementBlock
        Save-ContentInFile -filePath $filePath -fileContent $updatedContent
        Write-Log $successMessage
    } catch {
        Write-Log "An unexpected error occurred while processing the file." "ERROR"
        Write-Log "Details: $($_.Exception.Message)" "ERROR"
    }
}

function Enable-SpecificHttpHeaderSecurityBlock {
    param (
        [string]$filePath
    )

    $regexPattern = @"
<!--\s*<filter-mapping>\s*<filter-name>httpHeaderSecurity</filter-name>\s*<url-pattern>/\*</url-pattern>\s*<dispatcher>REQUEST</dispatcher>\s*</filter-mapping>\s*-->
"@

    $replacementBlock = @"
    <filter-mapping>
        <filter-name>httpHeaderSecurity</filter-name>
        <url-pattern>/*</url-pattern>
        <dispatcher>REQUEST</dispatcher>
    </filter-mapping>
"@

    Update-ContentInFile -filePath $filePath `
        -regexPattern $regexPattern `
        -replacementBlock $replacementBlock `
        -successMessage "Successfully uncommented the specific httpHeaderSecurity block in $filePath" `
        -errorMessage "The specific httpHeaderSecurity block was not found in the file."
}

function Update-HttpHeaderSecurityFilterBlock {
    param (
        [string]$filePath
    )

    $regexPattern = @"
<!--\s*<filter>\s*<filter-name>\s*httpHeaderSecurity\s*<\/filter-name>\s*<filter-class>\s*[^<]*HttpHeaderSecurityFilter\s*<\/filter-class>\s*<async-supported>\s*.*?\s*<\/async-supported>\s*<\/filter>\s*-->
"@

    $replacementBlock = @"
    <filter>
        <filter-name>httpHeaderSecurity</filter-name>
        <filter-class>org.apache.catalina.filters.HttpHeaderSecurityFilter</filter-class>
        <async-supported>true</async-supported>
        <init-param>
            <param-name>hstsEnabled</param-name>
            <param-value>true</param-value>
        </init-param>
        <init-param>
            <param-name>hstsMaxAgeSeconds</param-name>
            <param-value>31536000</param-value>
        </init-param>
        <init-param>
            <param-name>hstsIncludeSubDomains</param-name>
            <param-value>false</param-value>
        </init-param>
        <init-param>
            <param-name>antiClickJackingEnabled</param-name>
            <param-value>false</param-value>
        </init-param>
        <init-param>
            <param-name>blockContentTypeSniffingEnabled</param-name>
            <param-value>true</param-value>
        </init-param>
        <init-param>
            <param-name>xssProtectionEnabled</param-name>
            <param-value>true</param-value>
        </init-param>
    </filter>
"@

    Update-ContentInFile -filePath $filePath `
        -regexPattern $regexPattern `
        -replacementBlock $replacementBlock `
        -successMessage "Successfully updated the HttpHeaderSecurityFilterBlock block in $filePath" `
        -errorMessage "The HttpHeaderSecurityFilterBlock block was not found in the file."
}

function Update-FileWithRegex {
    param (
        [string]$filePath,
        [string]$pattern,
        [string]$replacement,
        [string]$successMessage,
        [string]$errorMessage = "An error occurred while processing the file."
    )

    try {
        $fileContent = Read-FileContent -filePath $filePath
        if ($fileContent -match $pattern) {
            $matchedContent = $matches[0]
            $escapedMatchedContent = [regex]::Escape($matchedContent)
            $updatedContent = $fileContent -replace $escapedMatchedContent, $replacement.Replace("{MATCHED_CONTENT}", $matchedContent)
            Save-ContentInFile -filePath $filePath -fileContent $updatedContent
            Write-Log $successMessage
        } else {
            Write-Host "No match found in $filePath."
        }
    } catch {
        Write-Log $errorMessage "ERROR"
        exit 1
    }
}

function Disable-ValveTag {
    param (
        [string]$filePath
    )

    $pattern = '(?s)<Valve\s+className="[^"]*RemoteAddrValve"[^>]*allow="[^"]*"[^>]*/>'
    $replacement = "<!-- {MATCHED_CONTENT} -->"
    $successMessage = "Successfully commented out the Valve tag from $filePath"
    Update-FileWithRegex -filePath $filePath -pattern $pattern -replacement $replacement -successMessage $successMessage
}

function Update-FieldInFile {
    param (
        [string]$batFilePath,
        [string]$fieldValue,
        [string]$fieldName
    )
    if (-not (Test-Path $batFilePath)) {
        Write-Log "Source file '$batFilePath' not found. Expected it to exist in non-prod envs." "WARN"
        return
    }

    $pattern = "(?<=set $fieldName=).*"
    $replacement = "`"$fieldValue`""
    $successMessage = "Successfully updated $fieldName in $batFilePath"
    Update-FileWithRegex -filePath $batFilePath -pattern $pattern -replacement $replacement -successMessage $successMessage
}

function Log-ExampleScript {
    Write-Host "###################################   Example Start   ##########################################"
    Write-Host "Run the following to list down the Tomcat services: "
    Write-Host @'
Get-Service |
    Where-Object { $_.DisplayName -like "*Tomcat*" -or $_.Name -like "*Tomcat*" } |
    Select-Object Status, Name, DisplayName, @{Name="StartupType";Expression={(Get-WmiObject -Class Win32_Service -Filter "Name='$($_.Name)'").StartMode}} |
    Format-Table -AutoSize
'@
    Write-Host @'
$SecurePassword = ConvertTo-SecureString "Hell0W@rld" -AsPlainText -Force
'@
    Write-Host @'
.\upgrade_tomcat.ps1 `
    -maxMemoryPool "4096" `
    -initialMemoryPool "256" `
    -jvmDLLPath "D:\java\jre8.0.412-x64zulu\bin\server\jvm.dll" `
    -serviceToUninstall "TOMCAT99364_SRVA" `
    -currentServiceToUpgrade "TOMCAT99664_SRVA" `
    -upgradedServiceName "$upgradedServiceName" `
    -setupLogOnCreds $true `
    -tomcatInstallationDrive "D:" `
    -tomcatLogOnPassword $SecurePassword `
    -tomcatLogOnUsername "svc_octane_dev@octaneaudev.internal"
'@
    Write-Host "###################################   Example End     ##########################################"
}

$stepCounter = -1
$tomcatDirName = "tomcat"
$upgradedSrvaDirName = "srva"
$upgradedSrvaDir = Join-Path -Path $tomcatDirName -ChildPath $upgradedSrvaDirName
$currentSrvaDir = Join-Path -Path $tomcatInstallationDrive -ChildPath $upgradedSrvaDir

# Prepare the new Tomcat folder with all required files copied and updated
try {
    Write-Log "Step $((++$stepCounter)): Test that the '$currentSrvaDir' folder exists."
    if (-not (Test-Path $currentSrvaDir)) {
        Write-Log "The specified $currentSrvaDir folder does not exist. Does it have a different name or path?" "ERROR"
        exit 1
    }

    Write-Log "Step $((++$stepCounter)): Unzip the Tomcat upgrade zip"
    Expand-Tomcat  -zipFilePath $tomcatZipPath -folderName $upgradedSrvaDir -ErrorAction Stop

    Write-Log "Step $((++$stepCounter)): Delete following folders"
    Remove-SpecifiedItem -itemPath "$upgradedSrvaDir\webapps\docs" -ErrorAction Stop
    Remove-SpecifiedItem -itemPath "$upgradedSrvaDir\webapps\examples" -ErrorAction Stop

    Write-Log "Step $((++$stepCounter)): Backup index and favicon"
    Backup-File -filePath "$upgradedSrvaDir\webapps\ROOT\favicon.ico" -ErrorAction Stop
    Backup-File -filePath "$upgradedSrvaDir\webapps\ROOT\index.jsp" -ErrorAction Stop

    Write-Log "Step $((++$stepCounter)): Copy following files from $currentSrvaDir to $upgradedSrvaDir"
    Copy-TomcatFiles -currentSrvaDir $currentSrvaDir -upgradedSrvaDirName $upgradedSrvaDir -ErrorAction Stop

    Write-Log "Step $((++$stepCounter)): Update $upgradedSrvaDir\conf\tomcat-users.xml"
    Add-TomcatUserRolesAndUser -xmlFilePath "$upgradedSrvaDir\conf\tomcat-users.xml" -ErrorAction Stop

    Write-Log "Step $((++$stepCounter)).a: Update $upgradedSrvaDir\conf\web.xml"
    Add-StrictQuoteEscaping -xmlFilePath "$upgradedSrvaDir\conf\web.xml" -ErrorAction Stop

    Write-Log "Step ${stepCounter}.b: Update $upgradedSrvaDir\conf\web.xml"
    Enable-SpecificHttpHeaderSecurityBlock -filePath $upgradedSrvaDir\conf\web.xml -ErrorAction Stop

    Write-Log "Step ${stepCounter}.c: Update $upgradedSrvaDir\conf\web.xml"
    Update-HttpHeaderSecurityFilterBlock -filePath $upgradedSrvaDir\conf\web.xml -ErrorAction Stop

    Write-Log "Step $((++$stepCounter)): Update $upgradedSrvaDir\webapps\manager\META-INF\context.xml"
    Disable-ValveTag -filePath $upgradedSrvaDir\webapps\manager\META-INF\context.xml -ErrorAction Stop

#    $upgradedServiceName = Get-VersionSpecificFilename -zipFilePath $tomcatZipPath
    Write-Log "Step $((++$stepCounter)): Duplicate $upgradedSrvaDir\bin\tomcat9w.exe and rename to $upgradedSrvaDir\bin\${upgradedServiceName}.exe"
    Copy-TomcatExecutable -newFileName $upgradedServiceName -upgradedSrvaDirName $upgradedSrvaDir -ErrorAction Stop

    Write-Log "Step $((++$stepCounter)): Modify service name and temp directory inside $tomcatDirName\restart_tomcat.bat"
    Update-FieldInFile -batFilePath $tomcatDirName\restart_tomcat.bat -fieldValue $upgradedServiceName -fieldName "tomcatServiceName" -ErrorAction Stop

    Write-Log "Upgrade ready, proceed with running the upgrade script."
    Log-ExampleScript

#    return $upgradedServiceName
} catch {
    Write-Log "An error occurred while setting up the new tomcat folder. Details: $($_.Exception.Message)" "ERROR"
    exit 1
}
