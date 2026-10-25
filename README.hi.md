# IIS + PHP FastCGI Auto-Deploy

[![PowerShell](https://img.shields.io/badge/PowerShell-7.5+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![प्लेटफ़ॉर्म](https://img.shields.io/badge/Platform-Windows%2011%2FServer%202019+-success.svg)](https://www.microsoft.com/windows)

<!-- md-i18n:switcher -->
**अन्य भाषाओं में:** [English](README.md) · [Deutsch](README.de.md) · [中文](README.zh.md) · हिन्दी · [Español](README.es.md) · [Русский](README.ru.md)

Windows 11 / Server पर FastCGI के माध्यम से PHP समर्थन के साथ IIS की **पूरी सेटअप प्रक्रिया को स्वचालित करने** वाली PowerShell स्क्रिप्ट।  
PHP-आधारित वेबमेल (जैसे Roundcube) या कस्टम डोमेन वाली किसी भी PHP वेबसाइट को तेज़ी से डिप्लॉय करने के लिए उपयुक्त।

## विशेषताएँ

- ✅ **IIS का स्वचालित इंस्टॉलेशन** – आवश्यक Windows फ़ीचर (IIS-WebServerRole, IIS-CGI) सक्षम करता है
- ✅ **स्मार्ट PHP डाउनलोड** – PHP संस्करण के आधार पर सही कंपाइलर संस्करण (vs16/vs17) पहचानता है
- ✅ **Visual C++ Redistributable की जाँच** – अनुपस्थित होने पर नवीनतम VC++ 2015-2022 x64 इंस्टॉल करता है
- ✅ **इडेम्पोटेंट** – कई बार चलाना सुरक्षित है; पहले से पूरे हुए चरण छोड़ देता है
- ✅ **FastCGI कॉन्फ़िगरेशन** – PHP को FastCGI एप्लिकेशन के रूप में पंजीकृत करता है और `*.php` हैंडलर जोड़ता है
- ✅ **IIS application pool और वेबसाइट का निर्माण** – अनुकूलन योग्य नाम, host header, port और physical path के साथ
- ✅ **फ़ोल्डर अनुमतियाँ** – `IUSR` को स्वतः read/execute पहुँच देता है
- ✅ **परीक्षण पृष्ठ** – सेटअप सत्यापित करने के लिए सरल `phpinfo()` फ़ाइल बनाता है
- ✅ **PowerShell 7.5+ के साथ काम करता है** – IIS cmdlet के लिए Windows PowerShell compatibility का उपयोग करता है

## पूर्वापेक्षाएँ

- Windows 11 / Windows Server 2019 या उससे नया
- एडमिनिस्ट्रेटर अधिकार
- इंटरनेट कनेक्शन (PHP और VC++ Redistributable डाउनलोड करने के लिए)

## उपयोग

1. इस रिपॉज़िटरी को **क्लोन या डाउनलोड** करें।
2. **PowerShell 7.5+ को एडमिनिस्ट्रेटर के रूप में** खोलें।
3. स्क्रिप्ट चलाएँ:

   ```powershell
   .\Setup-IIS-PHP.ps1
