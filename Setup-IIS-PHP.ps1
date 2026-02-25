<#
.SYNOPSIS
    Automated IIS + PHP (FastCGI) setup for a custom website on Windows 11 / Server.
.DESCRIPTION
    This script automates the complete setup of IIS with PHP support via FastCGI for a specified domain (e.g., mail.MyDomain.com).
    It checks for administrator privileges, enables required Windows features, installs the necessary Visual C++ Redistributable,
    downloads and configures PHP, creates an IIS application pool and website, sets up FastCGI handler, configures default documents,
    and creates a test phpinfo() page. The script is idempotent – safe to run multiple times.
.PARAMETER SiteName
    IIS site name (default: mail.MyDomain.com).
.PARAMETER SiteHostName
    Host header for the site (default: mail.MyDomain.com).
.PARAMETER SitePath
    Physical path for website files (default: C:\inetpub\mail).
.PARAMETER PhpVersion
    PHP version to install (default: 8.5.1). Determines the required Visual C++ Redistributable (vs16 for PHP <8.4, vs17 for PHP 8.4+).
.PARAMETER PhpInstallPath
    Directory where PHP will be installed (default: C:\PHP).
.PARAMETER HttpPort
    HTTP port for the site (default: 80).
.EXAMPLE
    .\Setup-IIS-PHP.ps1
    Runs with default parameters: sets up mail.MyDomain.com on port 80 with PHP 8.5.1.
.EXAMPLE
    .\Setup-IIS-PHP.ps1 -PhpVersion 8.4.6 -HttpPort 8080
    Installs PHP 8.4.6 and configures the site on port 8080.
.NOTES
    Author:  Mikhail Deynekin (https://deynekin.com) / Paul Mann (https://github.com/paulmann)
    Email:   mid1977@gmail.com
    Requires: Administrator privileges, Windows 11/Server 2019+, Internet connection.
    GitHub:  https://github.com/paulmann/IIS-PHP-FastCGI-AutoDeploy
#>

[CmdletBinding()]
param(
    [string]$SiteName       = "mail.MyDomain.com",
    [string]$SiteHostName   = "mail.MyDomain.com",
    [string]$SitePath       = "C:\inetpub\mydomain",
    [string]$PhpVersion     = "8.5.1",
    [string]$PhpInstallPath = "C:\PHP",
    [int]$HttpPort          = 80
)

#region Helper Functions

function Test-Administrator {
    <#
    .SYNOPSIS
        Checks if the script is running with administrator privileges.
    #>
    $identity  = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-IISFeatures {
    <#
    .SYNOPSIS
        Enables IIS Web Server and CGI role features.
    #>
    Write-Host ">>> Checking and enabling IIS and CGI features..." -ForegroundColor Cyan
    $features = @('IIS-WebServerRole', 'IIS-CGI')
    $restartNeeded = $false
    foreach ($feature in $features) {
        $state = (Get-WindowsOptionalFeature -Online -FeatureName $feature).State
        if ($state -ne 'Enabled') {
            Write-Host "Enabling feature: $feature"
            $result = Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
            if ($result.RestartNeeded) {
                Write-Warning "Feature $feature requires a system restart."
                $restartNeeded = $true
            }
        } else {
            Write-Host "Feature already enabled: $feature"
        }
    }
    if ($restartNeeded) {
        Write-Host "`nA reboot is required. Please restart the computer and run the script again." -ForegroundColor Red
        exit 2
    }
}

function Initialize-IISModule {
    <#
    .SYNOPSIS
        Imports the WebAdministration module (via Windows PowerShell compatibility) for IIS management.
    #>
    if (-not (Get-Module -Name WebAdministration -ErrorAction SilentlyContinue)) {
        Write-Host "Importing WebAdministration module (via Windows PowerShell)..." -ForegroundColor Cyan
        Import-Module WebAdministration -UseWindowsPowerShell -ErrorAction Stop
    }
}

function Install-VisualCppRedist {
    <#
    .SYNOPSIS
        Downloads and installs the latest Visual C++ 2015-2022 Redistributable (x64) if not already present.
    #>
    Write-Host ">>> Checking Visual C++ Redistributable (x64)..." -ForegroundColor Cyan

    # Improved registry search: look for any entry containing "Visual C++ 2015-2022 Redistributable (x64)"
    $vcRedistInstalled = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue |
        Get-ItemProperty |
        Where-Object { $_.DisplayName -like "*Visual C++ 2015-2022 Redistributable (x64)*" } |
        Select-Object -First 1

    if ($vcRedistInstalled) {
        Write-Host "Visual C++ Redistributable is already installed." -ForegroundColor Yellow
        return
    }

    Write-Host "Downloading Visual C++ 2015-2022 Redistributable (x64)..." -ForegroundColor Cyan
    $url = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
    $out = "$env:TEMP\vc_redist.x64.exe"
    try {
        Invoke-WebRequest -Uri $url -OutFile $out -ErrorAction Stop
    } catch {
        throw "Failed to download VC++ Redistributable: $_"
    }

    Write-Host "Installing VC++ Redistributable quietly (may take a moment)..."
    $process = Start-Process -FilePath $out -ArgumentList "/quiet", "/norestart" -Wait -PassThru
    if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 3010 -and $process.ExitCode -ne 1638) {
        throw "VC++ Redist installation failed with exit code $($process.ExitCode)"
    }
    if ($process.ExitCode -eq 1638) {
        Write-Host "Visual C++ Redistributable is already installed (exit code 1638)." -ForegroundColor Yellow
    } else {
        Write-Host "Visual C++ Redistributable installed successfully." -ForegroundColor Green
    }
    Remove-Item $out -Force -ErrorAction SilentlyContinue
}

function Get-PhpDownloadUrl {
    <#
    .SYNOPSIS
        Builds the correct download URL for a given PHP version (x64, NTS, appropriate compiler version).
    #>
    param([string]$Version)

    $ver = [version]$Version
    $vsVersion = if ($ver -ge [version]'8.4') { "vs17" } else { "vs16" }
    $baseUrl   = "https://windows.php.net/downloads/releases"
    $fileName  = "php-$Version-nts-Win32-$vsVersion-x64.zip"
    return "$baseUrl/$fileName"
}

function Install-Php {
    <#
    .SYNOPSIS
        Downloads and extracts PHP if not already present.
    #>
    param(
        [string]$Version,
        [string]$InstallPath
    )
    Write-Host ">>> Installing PHP $Version into $InstallPath ..." -ForegroundColor Cyan
    if (-not (Test-Path $InstallPath)) {
        New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
    }
    $phpCgi = Join-Path $InstallPath "php-cgi.exe"
    # Fixed: removed extra closing parenthesis
    if (Test-Path $phpCgi) {
        Write-Host "PHP already present at $InstallPath, skipping download." -ForegroundColor Yellow
        return $phpCgi
    }

    $phpZipUrl  = Get-PhpDownloadUrl -Version $Version
    $phpZipFile = Join-Path $env:TEMP "php-$Version.zip"

    Write-Host "Checking URL availability: $phpZipUrl"
    try {
        $response = Invoke-WebRequest -Uri $phpZipUrl -Method Head -ErrorAction Stop
        if ($response.StatusCode -ne 200) { throw "URL returned code $($response.StatusCode)" }
    } catch {
        throw "URL $phpZipUrl is not accessible: $_"
    }

    Write-Host "Downloading PHP from $phpZipUrl ..."
    try {
        Invoke-WebRequest -Uri $phpZipUrl -OutFile $phpZipFile -ErrorAction Stop
    } catch {
        throw "Failed to download PHP: $_"
    }

    Write-Host "Extracting to $InstallPath ..."
    try {
        Expand-Archive -Path $phpZipFile -DestinationPath $InstallPath -Force -ErrorAction Stop
    } catch {
        throw "Extraction failed: $_"
    } finally {
        Remove-Item $phpZipFile -Force -ErrorAction SilentlyContinue
    }

    if (-not (Test-Path $phpCgi)) {
        throw "php-cgi.exe not found after extraction. Check the archive contents."
    }
    Write-Host "PHP installed successfully." -ForegroundColor Green
    return $phpCgi
}

function Add-FastCgiApplication {
    <#
    .SYNOPSIS
        Registers the PHP CGI executable as a FastCGI application in IIS.
    #>
    param([string]$PhpCgiPath)
    Write-Host ">>> Configuring FastCGI for $PhpCgiPath ..." -ForegroundColor Cyan
    $fcgiSection = "system.webServer/fastCgi"
    $existing = Get-WebConfiguration -Filter "$fcgiSection/application[@fullPath='$PhpCgiPath']" `
                                     -ErrorAction SilentlyContinue
    if (-not $existing) {
        Add-WebConfiguration -Filter $fcgiSection -PSPath "MACHINE/WEBROOT/APPHOST" -Value @{
            fullPath     = $PhpCgiPath
            arguments    = ""
            maxInstances = 4
        } -ErrorAction Stop
        Write-Host "FastCGI application added."
    } else {
        Write-Host "FastCGI application already exists."
    }
}

function New-OrUpdateAppPool {
    <#
    .SYNOPSIS
        Creates or updates the IIS application pool for the site.
    #>
    param([string]$AppPoolName)
    Write-Host ">>> Checking application pool '$AppPoolName' ..." -ForegroundColor Cyan

    if (-not (Get-WebAppPoolState -Name $AppPoolName -ErrorAction SilentlyContinue)) {
        Write-Host "Creating new application pool."
        New-WebAppPool -Name $AppPoolName | Out-Null
    }

    $poolState = (Get-WebAppPoolState -Name $AppPoolName).Value
    $wasStarted = ($poolState -eq 'Started')

    if ($wasStarted) {
        Write-Host "Stopping pool to apply configuration changes."
        Stop-WebAppPool -Name $AppPoolName
        Start-Sleep -Seconds 2
    }

    $filter = "/system.applicationHost/applicationPools/add[@name='$AppPoolName']"
    Set-WebConfigurationProperty -Filter $filter `
        -Name managedRuntimeVersion -Value '' `
        -PSPath "MACHINE/WEBROOT/APPHOST" -ErrorAction Stop
    Set-WebConfigurationProperty -Filter $filter `
        -Name enable32BitAppOnWin64 -Value $false `
        -PSPath "MACHINE/WEBROOT/APPHOST" -ErrorAction Stop

    if ($wasStarted) {
        Write-Host "Starting pool."
        Start-WebAppPool -Name $AppPoolName
    }
    Write-Host "Application pool ready."
}

function New-OrReplaceWebsite {
    <#
    .SYNOPSIS
        Creates (or recreates) the IIS website with specified bindings.
    #>
    param(
        [string]$Name,
        [string]$HostHeader,
        [string]$PhysicalPath,
        [string]$AppPool,
        [int]$Port
    )
    Write-Host ">>> Creating website '$Name' ..." -ForegroundColor Cyan
    if (Get-Website -Name $Name -ErrorAction SilentlyContinue) {
        Write-Host "Removing existing website '$Name'."
        Remove-Website -Name $Name
        Start-Sleep -Seconds 1
    }
    New-Website -Name $Name `
                -PhysicalPath $PhysicalPath `
                -ApplicationPool $AppPool `
                -Port $Port `
                -HostHeader $HostHeader `
                -IPAddress "*" | Out-Null

    $site = Get-Website -Name $Name
    if ($site.State -ne 'Started') {
        Write-Host "Starting website."
        Start-Website -Name $Name
    }
    Write-Host "Website created."
}

function Add-PhpHandler {
    <#
    .SYNOPSIS
        Adds the FastCGI handler mapping for *.php files to the site.
    #>
    param(
        [string]$SiteName,
        [string]$PhpCgiPath
    )
    Write-Host ">>> Adding *.php handler for site '$SiteName' ..." -ForegroundColor Cyan
    $handlerName = "PHP_via_FastCGI"
    $pspath   = "MACHINE/WEBROOT/APPHOST"
    $location = $SiteName

    $existing = Get-WebHandler -Name $handlerName `
                               -PSPath $pspath `
                               -Location $location `
                               -ErrorAction SilentlyContinue
    if (-not $existing) {
        New-WebHandler -Name $handlerName `
                       -Path "*.php" `
                       -Verb "GET,HEAD,POST" `
                       -Modules "FastCgiModule" `
                       -ScriptProcessor $PhpCgiPath `
                       -ResourceType "File" `
                       -PSPath $pspath `
                       -Location $location `
                       -ErrorAction Stop | Out-Null
        Write-Host "Handler added."
    } else {
        Write-Host "Handler already exists."
    }
}

function Set-FolderPermissions {
    <#
    .SYNOPSIS
        Grants read/execute permission to IUSR for the website folder.
    #>
    param([string]$Path)
    Write-Host ">>> Setting folder permissions for IUSR on '$Path' ..." -ForegroundColor Cyan
    $acl = Get-Acl $Path
    $iusr = New-Object System.Security.Principal.NTAccount("IUSR")
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $iusr,
        "ReadAndExecute",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )
    $acl.SetAccessRule($accessRule)
    Set-Acl $Path $acl
    Write-Host "Permissions set."
}

function New-TestPhpFile {
    <#
    .SYNOPSIS
        Creates a simple phpinfo() test file if it doesn't already exist.
    #>
    param([string]$Path)
    $indexFile = Join-Path $Path "index.php"
    if (-not (Test-Path $indexFile)) {
        Set-Content -Path $indexFile -Value "<?php phpinfo(); ?>" -Encoding UTF8
        Write-Host "Test index.php created."
    } else {
        Write-Host "index.php already exists, skipping creation."
    }
}

function Set-DefaultDocuments {
    <#
    .SYNOPSIS
        Sets the default documents for the website in order: index.php, index.html, index.htm.
    #>
    param(
        [string]$SiteName,
        [string[]]$Documents = @("index.php", "index.html", "index.htm")
    )
    Write-Host ">>> Setting default documents for site '$SiteName' ..." -ForegroundColor Cyan
    $filter = "system.webServer/defaultDocument"
    $pspath = "MACHINE/WEBROOT/APPHOST"
    $location = $SiteName

    # Enable the default document feature
    Set-WebConfigurationProperty -Filter $filter -Name enabled -Value $true -PSPath $pspath -Location $location -ErrorAction Stop

    # Replace the entire files collection with the desired documents
    $docsArray = $Documents | ForEach-Object { @{value = $_} }
    Set-WebConfiguration -Filter "$filter/files" -PSPath $pspath -Location $location -Value $docsArray -ErrorAction Stop

    Write-Host "Default documents set to: $($Documents -join ', ')"
}

#endregion

# ---- Main execution ----
Clear-Host
Write-Host "=========================================================" -ForegroundColor Magenta
Write-Host "   IIS + PHP (FastCGI) Auto-Deploy for $SiteName" -ForegroundColor Magenta
Write-Host "=========================================================" -ForegroundColor Magenta

# Check administrator rights
if (-not (Test-Administrator)) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

# 1. Install required Windows features (IIS, CGI)
Install-IISFeatures

# 2. Import IIS management module
Initialize-IISModule

# 3. Install Visual C++ Redistributable (required for PHP)
Install-VisualCppRedist

# 4. Install PHP
$phpCgiPath = Install-Php -Version $PhpVersion -InstallPath $PhpInstallPath

# 5. Register PHP as FastCGI application
Add-FastCgiApplication -PhpCgiPath $phpCgiPath

# 6. Create website directory if missing
if (-not (Test-Path $SitePath)) {
    Write-Host "Creating website directory: $SitePath"
    New-Item -Path $SitePath -ItemType Directory -Force | Out-Null
}
Set-FolderPermissions -Path $SitePath

# 7. Create a test phpinfo() file
New-TestPhpFile -Path $SitePath

# 8. Create/update application pool
New-OrUpdateAppPool -AppPoolName $SiteName

# 9. Create/replace website
New-OrReplaceWebsite -Name $SiteName -HostHeader $SiteHostName `
                     -PhysicalPath $SitePath -AppPool $SiteName -Port $HttpPort

# 10. Add PHP handler for the site
Add-PhpHandler -SiteName $SiteName -PhpCgiPath $phpCgiPath

# 11. Set default documents (index.php, index.html, index.htm)
Set-DefaultDocuments -SiteName $SiteName

Write-Host "=========================================================" -ForegroundColor Green
Write-Host "Setup completed successfully!" -ForegroundColor Green
Write-Host "Your site is available at: http://$SiteHostName/" -ForegroundColor Yellow
Write-Host "Default documents set: index.php, index.html, index.htm" -ForegroundColor Yellow
Write-Host "Test PHP by visiting http://$SiteHostName/ (should show phpinfo)." -ForegroundColor Yellow
Write-Host "You can now deploy your PHP application (e.g., Roundcube) into $SitePath." -ForegroundColor Yellow
Write-Host "The installer (if any) will be at http://$SiteHostName/installer/" -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Green
