# IIS + PHP FastCGI Auto-Deploy

[![PowerShell](https://img.shields.io/badge/PowerShell-7.5+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Plataforma](https://img.shields.io/badge/Platform-Windows%2011%2FServer%202019+-success.svg)](https://www.microsoft.com/windows)

<!-- md-i18n:switcher -->
**En otros idiomas:** [English](README.md) · [Deutsch](README.de.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md) · Español · [Русский](README.ru.md)

Un script de PowerShell para **automatizar la configuración completa** de IIS con soporte de PHP mediante FastCGI en Windows 11 / Server.  
Perfecto para desplegar rápidamente un webmail basado en PHP (como Roundcube) o cualquier sitio PHP con un dominio propio.

## Características

- ✅ **Instalación automática de IIS** – habilita las características de Windows necesarias (IIS-WebServerRole, IIS-CGI)
- ✅ **Descarga inteligente de PHP** – detecta la versión correcta del compilador (vs16/vs17) según la versión de PHP
- ✅ **Comprobación de Visual C++ Redistributable** – instala el VC++ 2015-2022 x64 más reciente si falta
- ✅ **Idempotente** – se puede ejecutar varias veces sin riesgo; omite los pasos ya completados
- ✅ **Configuración de FastCGI** – registra PHP como aplicación FastCGI y añade el controlador `*.php`
- ✅ **Creación del grupo de aplicaciones y del sitio web de IIS** – con nombre, encabezado de host, puerto y ruta física personalizables
- ✅ **Permisos de carpetas** – concede automáticamente acceso de lectura y ejecución a `IUSR`
- ✅ **Página de prueba** – crea un archivo `phpinfo()` sencillo para verificar la configuración
- ✅ **Compatible con PowerShell 7.5+** – usa la capa de compatibilidad con Windows PowerShell para los cmdlets de IIS

## Requisitos previos

- Windows 11 / Windows Server 2019 o posterior
- Privilegios de administrador
- Conexión a Internet (para descargar PHP y Visual C++ Redistributable)

## Uso

1. **Clona o descarga** este repositorio.
2. Abre **PowerShell 7.5+ como administrador**.
3. Ejecuta el script:

   ```powershell
   .\Setup-IIS-PHP.ps1
