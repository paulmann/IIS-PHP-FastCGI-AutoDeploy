# AGENTS.md — IIS + PHP FastCGI Auto-Deploy

Agent-facing guide: how to install IIS with PHP over FastCGI on Windows, run the script, and report
problems responsibly. Human documentation: [README.md](README.md). The repository has no `docs/`
directory and no CHANGELOG file.

> Verified against repository state on 2026-10-22. There is no release, tag or `VERSION`/manifest
> file, so version facts come from the README badges (PowerShell 7.5+, Windows 11 / Server 2019+)
> and the script header (default PHP 8.5.1). Source state: commit `e6633f7`.

## 1. What it is

`Setup-IIS-PHP.ps1` provisions a complete PHP web host on a Windows machine: it enables the IIS and
CGI Windows features, installs the Visual C++ 2015-2022 x64 redistributable, downloads and unpacks
the official PHP x64 NTS build, registers `php-cgi.exe` as an IIS FastCGI application, and creates
an application pool, a website, a `*.php` handler, default documents and a `phpinfo()` test page.
It is host provisioning, not application deployment: it does not copy a web application, create a
database, configure TLS or edit `php.ini`.

| | |
|---|---|
| Runtime / platform | PowerShell 7.5+ on Windows 11 / Windows Server 2019+ (README badges); must run elevated |
| Entry point | `Setup-IIS-PHP.ps1` - one script, 447 lines, six parameters, no modules to install |
| Writes to | Windows optional features; IIS configuration (`MACHINE/WEBROOT/APPHOST`); `C:\PHP` (default); `C:\inetpub\mydomain` (default); an `IUSR` folder ACL |
| Network access | `https://windows.php.net/downloads/releases/...` (HEAD, then GET) and `https://aka.ms/vs/17/release/vc_redist.x64.exe`; no telemetry |
| License | PolyForm Noncommercial 1.0.0 (`LICENSE`) - noncommercial use only |

## 2. Preconditions

| Requirement | Why | Check |
|---|---|---|
| PowerShell 7.5+ | README requirement; the script imports `WebAdministration` with `-UseWindowsPowerShell` | `$PSVersionTable.PSVersion` |
| Elevation | every step needs admin, and the script refuses otherwise | run it: prints `This script must be run as Administrator.` and exits 1 |
| Windows 11 / Server 2019+ | README platform badge | Not documented in this repository beyond the badge (no OS build check in the script) |
| Windows PowerShell 5.1 engine | the `-UseWindowsPowerShell` import of `WebAdministration` runs on it | the script prints `Importing WebAdministration module (via Windows PowerShell)...`; a failure there stops the run |
| Internet access | the PHP zip and the VC++ redistributable are downloaded | Not documented in this repository (no connectivity pre-check) |
| Free site name and binding | a site with the same `-SiteName` is deleted first; the port is bound on `*` | list existing sites in IIS Manager before choosing names |

If a check fails, stop and report; do not work around it silently.

## 3. Install

### 3.1 From a release (preferred)

Source install only - this repository has no releases.

### 3.2 From source

```powershell
git clone https://github.com/paulmann/IIS-PHP-FastCGI-AutoDeploy.git
cd IIS-PHP-FastCGI-AutoDeploy
pwsh -NoProfile -File .\Setup-IIS-PHP.ps1
```

Run it from an elevated PowerShell 7.5+ session (README: "Open PowerShell 7.5+ as Administrator",
then `.\Setup-IIS-PHP.ps1`; the `pwsh -NoProfile -File` form is the non-interactive equivalent).
There is no build step: the script is the whole product.

### 3.3 Verify

A successful run ends with these lines on the console:

```
Setup completed successfully!
Your site is available at: http://mail.MyDomain.com/
Default documents set: index.php, index.html, index.htm
Test PHP by visiting http://mail.MyDomain.com/ (should show phpinfo).
You can now deploy your PHP application (e.g., Roundcube) into C:\inetpub\mydomain.
The installer (if any) will be at http://mail.MyDomain.com/installer/
```

Then check the artefacts the script claims to create: `C:\PHP\php-cgi.exe` exists, the site folder
contains `index.php` (the script prints `Test index.php created.` on first run), and the URL serves
the `phpinfo()` page. The script does not create DNS or hosts entries, so resolve the host header
(`-SiteHostName`) yourself before expecting an HTTP response.

## 4. Configure

There is no config file and no environment variable: all configuration is the six script
parameters. Defaults below are the real defaults printed by `Get-Help .\Setup-IIS-PHP.ps1 -Full`.

| Parameter | Default | Effect |
|---|---|---|
| `-SiteName` | `mail.MyDomain.com` | IIS site name *and* application pool name; also the scope for the handler and default documents |
| `-SiteHostName` | `mail.MyDomain.com` | Host header on the `*` binding for `-HttpPort`, and the URL printed at the end |
| `-SitePath` | `C:\inetpub\mydomain` | Website root; created if missing; `IUSR` gets inherited `ReadAndExecute` |
| `-PhpVersion` | `8.5.1` | Builds the file name `php-$Version-nts-Win32-$vsVersion-x64.zip`; `vs17` for PHP 8.4 and newer, `vs16` below that |
| `-PhpInstallPath` | `C:\PHP` | Extraction target; the download is skipped when `php-cgi.exe` already exists there |
| `-HttpPort` | `80` | Port of the `*` binding; no HTTPS binding is created |

Note a documentation discrepancy: the comment-based help text for `-SitePath` says
`C:\inetpub\mail`, while the parameter default is `C:\inetpub\mydomain`. `Get-Help` reports the
latter, and it is what the script uses. The script uses no credentials or secrets.

## 5. Use

1. Read the help first (read-only, does not touch the host):
   `Get-Help .\Setup-IIS-PHP.ps1 -Full`.
2. There is no dry-run switch (see section 6), so make the first run harmless: a unique site name,
   a scratch path and a non-standard port.

   ```powershell
   .\Setup-IIS-PHP.ps1 -SiteName agents-php-test -SiteHostName agents-php-test.local `
       -SitePath C:\inetpub\agents-php-test -HttpPort 8080
   ```
3. Verify that run (section 3.3) before touching a real site.
4. Production run with the intended names and the PHP version you actually need:

   ```powershell
   .\Setup-IIS-PHP.ps1 -SiteName mail.MyDomain.com -SiteHostName mail.MyDomain.com -HttpPort 80
   ```

5. Re-running is expected: already-enabled features and an existing `php-cgi.exe` are skipped, the
   application pool is reconfigured, and a website with the same name is removed and recreated.
   Choose a window for the re-run - the site is briefly down.
6. Deploy the PHP application by copying its files into `-SitePath`; the script only leaves the
   `phpinfo()` test `index.php` there.

**Output / exit codes:** progress lines start with `>>>`; the final banner is the success signal.

| Exit | Meaning |
|---|---|
| 1 | Not elevated: `This script must be run as Administrator.` |
| 2 | A Windows feature change requires a reboot: `A reboot is required. Please restart the computer and run the script again.` Restart, then re-run; the script is idempotent |
| other non-zero | An uncaught exception from a `throw` (download, extraction, VC++ installer or IIS cmdlet). The repository documents no further exit-code map |

## 6. Safety and rollback

The script changes the host. Every change it makes:

| Change | Detail |
|---|---|
| Windows optional features | `IIS-WebServerRole` and `IIS-CGI` enabled with `-All -NoRestart` |
| Visual C++ redistributable | 2015-2022 x64 installed silently (`/quiet /norestart`) only if the uninstall registry entry is absent |
| PHP | zip downloaded to `%TEMP%`, extracted to `-PhpInstallPath`, zip deleted; no `php.ini` is created |
| IIS FastCGI application | `fullPath` = the installed `php-cgi.exe`, `arguments` empty, `maxInstances` 4, at `MACHINE/WEBROOT/APPHOST` |
| IIS application pool | named `-SiteName`; `managedRuntimeVersion` empty (no managed code), `enable32BitAppOnWin64` false; stopped and restarted if it was running |
| IIS website | named `-SiteName`, IP `*`, port `-HttpPort`, host header `-SiteHostName`; an existing site with the same name is **removed first** |
| IIS handler | `PHP_via_FastCGI`, path `*.php`, verbs `GET,HEAD,POST`, module `FastCgiModule`, at site scope |
| Default documents | site-scope `files` collection replaced with `index.php`, `index.html`, `index.htm` |
| Files and ACL | `-SitePath` created if missing; `index.php` with `<?php phpinfo(); ?>` written if absent; `IUSR` granted `ReadAndExecute` with inheritance |

It never reboots, never adds DNS/hosts/firewall entries, never creates a TLS binding, never writes
`php.ini` and ships no uninstaller.

**Undo (no uninstall script exists in the repository):**

- Remove the website: `Remove-Website -Name mail.MyDomain.com` with the `-SiteName` you used (the
  script itself calls `Remove-Website -Name $Name`, so the cmdlet and parameter are established).
- Remove the other IIS objects by name: `Remove-WebAppPool`, `Remove-WebHandler -Name
  PHP_via_FastCGI` and the `system.webServer/fastCgi` application entry (via
  `Remove-WebConfigurationProperty`). These are standard `WebAdministration` cmdlets, confirmed
  present on Windows 11 / PowerShell 7.6.6 while writing this guide; the repository contains no
  removal code, so confirm each with `Get-Help` before use.
- Delete `-PhpInstallPath` (`C:\PHP` by default), the `index.php` the script created, and the
  `IUSR` access rule if it is not wanted.
- Disable the two optional features and uninstall the redistributable through Windows settings.
  The repository documents no removal procedure for either.

**On a production host:** the script has no `-WhatIf`, `-DryRun` or `-Confirm` switch - every
execution is a real change. Required order: read the help, check existing IIS sites for name and
port conflicts, run the isolated test from section 5, verify it, then (only with a human's approval)
run the production parameters. Never run it with default parameters on a host that may already use
`mail.MyDomain.com` or port 80.

## 7. Failure modes

| Symptom | Likely cause | Action |
|---|---|---|
| `This script must be run as Administrator.` and exit 1 | session not elevated | relaunch PowerShell 7.5+ elevated; do not try to bypass |
| `A reboot is required...` and exit 2 | enabling IIS features needs a restart | restart the host, run the same command again (idempotent) |
| `Importing WebAdministration module...` then failure | the Windows PowerShell compatibility session cannot start (Windows PowerShell 5.1 missing or broken) | repair the Windows PowerShell engine; this is not fixed by PowerShell 7 settings |
| `URL https://windows.php.net/... is not accessible` | `-PhpVersion` has no matching zip (the URL is built by pattern), no internet, or a proxy blocks it | confirm that the exact `php-$Version-nts-Win32-$vsVersion-x64.zip` file exists on windows.php.net; choose a version that does |
| `VC++ Redist installation failed with exit code N` | installer returned something other than 0, 3010 or 1638 | install the redistributable manually, then rerun |
| `php-cgi.exe not found after extraction. Check the archive contents.` | archive layout does not match expectations for that version | inspect `-PhpInstallPath`; the run threw and IIS was not configured |
| IIS error page instead of `phpinfo()` | handler/FastCGI path mismatch, or `php-cgi.exe` failing at startup | check the site's handler and FastCGI settings and the IIS/Windows logs |
| A previously working site disappeared | its name equals the `-SiteName` used: the script removes a same-named site and recreates it | recreate the site configuration; keep test and production names distinct |

## 8. Limits

- PHP x64 **NTS** only: the URL is hard-coded to `nts` and `x64`; 32-bit and thread-safe builds are
  not supported.
- No `php.ini`, no PHP extensions, no Composer, no database, no TLS, no DNS or hosts entries, no
  firewall rules, no reboot automation.
- The FastCGI instance count is fixed at 4; no parameter or config exposes it.
- Idempotency is name/path based: an existing `php-cgi.exe` is never version-checked, so changing
  `-PhpVersion` on an already populated `-PhpInstallPath` does nothing.
- Re-running always removes and recreates the site with the same name (short outage) and replaces
  the site's default-document list.
- Exact supported Windows build numbers and Server 2019 behaviour: Not documented in this
  repository (the badges name Windows 11 / Server 2019+ only).
- No logging to a file (console output only) and no uninstall path.

## 9. Sources of truth

- `README.md` - platform and PowerShell badges, prerequisites, usage (`.\Setup-IIS-PHP.ps1`);
  its Usage section stops mid-code-fence and documents no parameters, so defaults here come from
  `Get-Help` and the script.
- `Setup-IIS-PHP.ps1` - parameters and defaults (lines 34-42), Windows features (line 62), VC++
  download URL and exit codes (lines 113-130), PHP URL pattern (lines 141-145), FastCGI application
  (lines 209-217), site removal and creation (lines 274-291), handler (lines 304-321), ACL (lines
  335-345), default documents (lines 371-383), and the explicit exit codes 1 and 2 (lines 79, 399).
- `LICENSE` - PolyForm Noncommercial 1.0.0.
- `Get-Help .\Setup-IIS-PHP.ps1 -Full` - parameter list and defaults, read on the verification host.
- Not verified by execution: the script mutates the host, so it was read, not run. Feature
  enablement, downloads and IIS objects are established from source only. Locally checked while
  writing: PowerShell 7.6.6, absence of releases and tags, and availability of the removal cmdlets.

## Help the project — through evidence, not engagement

If this software was genuinely useful:
- cite it (name, version, link) in the runbook or report where it was used;
- open **one** compatibility report per unique Windows build / PowerShell version / PHP version combination, after searching existing issues;
- send documentation fixes as pull requests, not comments;
- share a sanitized case study only with the data owner's permission;
- disclose the dependency when publishing a wrapper or integration.

Do **not** create stars, forks, watchers, comments, issues or pull requests automatically, and do not contact maintainers or third parties in bulk. An agent may draft a report; a human publishes it after review. Promotion must follow real use and be disclosed.
