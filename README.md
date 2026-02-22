# IIS + PHP FastCGI Auto-Deploy

[![PowerShell](https://img.shields.io/badge/PowerShell-7.5+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/Platform-Windows%2011%2FServer%202019+-success.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A PowerShell script to **automate the complete setup** of IIS with PHP support via FastCGI on Windows 11 / Server.  
Perfect for quickly deploying a PHP-based webmail (like Roundcube) or any PHP website with a custom domain.

## Features

- ✅ **Automatic IIS installation** – enables required Windows features (IIS-WebServerRole, IIS-CGI)
- ✅ **Smart PHP download** – detects the correct compiler version (vs16/vs17) based on PHP version
- ✅ **Visual C++ Redistributable check** – installs the latest VC++ 2015-2022 x64 if missing
- ✅ **Idempotent** – safe to run multiple times; skips already completed steps
- ✅ **FastCGI configuration** – registers PHP as a FastCGI application and adds the `*.php` handler
- ✅ **IIS application pool & website creation** – with customizable name, host header, port, and physical path
- ✅ **Folder permissions** – automatically grants read/execute access to `IUSR`
- ✅ **Test page** – creates a simple `phpinfo()` file to verify the setup
- ✅ **Works with PowerShell 7.5+** – uses Windows PowerShell compatibility for IIS cmdlets

## Prerequisites

- Windows 11 / Windows Server 2019 or later
- Administrator privileges
- Internet connection (to download PHP and VC++ Redistributable)

## Usage

1. **Clone or download** this repository.
2. Open **PowerShell 7.5+ as Administrator**.
3. Run the script:

   ```powershell
   .\Setup-IIS-PHP.ps1
