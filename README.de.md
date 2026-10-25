# IIS + PHP FastCGI Auto-Deploy

[![PowerShell](https://img.shields.io/badge/PowerShell-7.5+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Plattform](https://img.shields.io/badge/Platform-Windows%2011%2FServer%202019+-success.svg)](https://www.microsoft.com/windows)

<!-- md-i18n:switcher -->
**In anderen Sprachen:** [English](README.md) · Deutsch · [中文](README.zh.md) · [हिन्दी](README.hi.md) · [Español](README.es.md) · [Русский](README.ru.md)

Ein PowerShell-Skript zur **vollständigen Automatisierung der Einrichtung** von IIS mit PHP-Unterstützung über FastCGI unter Windows 11 / Server.  
Ideal, um eine PHP-basierte Webmail (etwa Roundcube) oder eine beliebige PHP-Website mit eigener Domain schnell bereitzustellen.

## Funktionen

- ✅ **Automatische IIS-Installation** – aktiviert die erforderlichen Windows-Features (IIS-WebServerRole, IIS-CGI)
- ✅ **Intelligenter PHP-Download** – ermittelt anhand der PHP-Version die passende Compilerversion (vs16/vs17)
- ✅ **Prüfung des Visual C++ Redistributable** – installiert bei Bedarf das aktuelle VC++ 2015-2022 x64
- ✅ **Idempotent** – mehrfach ausführbar; bereits abgeschlossene Schritte werden übersprungen
- ✅ **FastCGI-Konfiguration** – registriert PHP als FastCGI-Anwendung und fügt den Handler `*.php` hinzu
- ✅ **Anlegen von IIS-Anwendungspool und Website** – mit anpassbarem Namen, Hostheader, Port und physischem Pfad
- ✅ **Ordnerberechtigungen** – erteilt `IUSR` automatisch Lese- und Ausführungsrechte
- ✅ **Testseite** – erstellt eine einfache `phpinfo()`-Datei zur Überprüfung der Einrichtung
- ✅ **Läuft mit PowerShell 7.5+** – nutzt die Windows-PowerShell-Kompatibilität für die IIS-Cmdlets

## Voraussetzungen

- Windows 11 / Windows Server 2019 oder neuer
- Administratorrechte
- Internetverbindung (zum Herunterladen von PHP und VC++ Redistributable)

## Verwendung

1. Dieses Repository **klonen oder herunterladen**.
2. **PowerShell 7.5+ als Administrator** öffnen.
3. Skript ausführen:

   ```powershell
   .\Setup-IIS-PHP.ps1
