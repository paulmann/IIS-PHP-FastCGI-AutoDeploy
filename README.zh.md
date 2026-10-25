# IIS + PHP FastCGI Auto-Deploy

[![PowerShell](https://img.shields.io/badge/PowerShell-7.5+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![平台](https://img.shields.io/badge/Platform-Windows%2011%2FServer%202019+-success.svg)](https://www.microsoft.com/windows)

<!-- md-i18n:switcher -->
**其他语言：** [English](README.md) · [Deutsch](README.de.md) · 中文 · [हिन्दी](README.hi.md) · [Español](README.es.md) · [Русский](README.ru.md)

一个 PowerShell 脚本，用于在 Windows 11 / Server 上**自动完成**通过 FastCGI 为 IIS 配置 PHP 支持的整个安装过程。  
适合快速部署基于 PHP 的 Web 邮件（如 Roundcube），或任何带自定义域名的 PHP 网站。

## 功能

- ✅ **自动安装 IIS** – 启用所需的 Windows 功能（IIS-WebServerRole、IIS-CGI）
- ✅ **智能下载 PHP** – 根据 PHP 版本判断正确的编译器版本（vs16/vs17）
- ✅ **检查 Visual C++ 可再发行组件** – 若缺失则安装最新的 VC++ 2015-2022 x64
- ✅ **幂等** – 可安全地重复运行；跳过已完成的步骤
- ✅ **FastCGI 配置** – 将 PHP 注册为 FastCGI 应用程序，并添加 `*.php` 处理程序
- ✅ **创建 IIS 应用程序池与网站** – 名称、主机头、端口和物理路径均可自定义
- ✅ **文件夹权限** – 自动为 `IUSR` 授予读取/执行访问权限
- ✅ **测试页** – 创建一个简单的 `phpinfo()` 文件以验证配置
- ✅ **支持 PowerShell 7.5+** – 通过 Windows PowerShell 兼容层调用 IIS cmdlet

## 先决条件

- Windows 11 / Windows Server 2019 或更高版本
- 管理员权限
- Internet 连接（用于下载 PHP 和 VC++ 可再发行组件）

## 使用

1. **克隆或下载**本仓库。
2. 以管理员身份打开 **PowerShell 7.5+**。
3. 运行脚本：

   ```powershell
   .\Setup-IIS-PHP.ps1
