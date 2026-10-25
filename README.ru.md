# IIS + PHP FastCGI Auto-Deploy

[![PowerShell](https://img.shields.io/badge/PowerShell-7.5+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Платформа](https://img.shields.io/badge/Platform-Windows%2011%2FServer%202019+-success.svg)](https://www.microsoft.com/windows)

<!-- md-i18n:switcher -->
**На других языках:** [English](README.md) · [Deutsch](README.de.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md) · [Español](README.es.md) · Русский

Скрипт PowerShell, который **полностью автоматизирует установку** IIS с поддержкой PHP через FastCGI на Windows 11 / Server.  
Подходит для быстрого развёртывания веб-почты на PHP (например, Roundcube) или любого PHP-сайта с собственным доменом.

## Возможности

- ✅ **Автоматическая установка IIS** — включает нужные компоненты Windows (IIS-WebServerRole, IIS-CGI)
- ✅ **Подбор версии PHP** — определяет нужную версию компилятора (vs16/vs17) по версии PHP
- ✅ **Проверка Visual C++ Redistributable** — устанавливает последний VC++ 2015-2022 x64, если его нет
- ✅ **Идемпотентность** — скрипт можно запускать повторно; уже выполненные шаги пропускаются
- ✅ **Настройка FastCGI** — регистрирует PHP как приложение FastCGI и добавляет обработчик `*.php`
- ✅ **Пул приложений и сайт IIS** — с настраиваемым именем, заголовком узла, портом и физическим путём
- ✅ **Права на папку** — автоматически выдаёт `IUSR` права на чтение и выполнение
- ✅ **Тестовая страница** — создаёт простой файл `phpinfo()` для проверки настройки
- ✅ **Работает с PowerShell 7.5+** — использует режим совместимости Windows PowerShell для командлетов IIS

## Требования

- Windows 11 / Windows Server 2019 или новее
- Права администратора
- Подключение к интернету (для загрузки PHP и VC++ Redistributable)

## Использование

1. **Склонируйте или скачайте** этот репозиторий.
2. Откройте **PowerShell 7.5+ от имени администратора**.
3. Запустите скрипт:

   ```powershell
   .\Setup-IIS-PHP.ps1
