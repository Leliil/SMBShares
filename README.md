# Windows SMB Shares Manager

![Batch](https://img.shields.io/badge/Batch-4D4D4D?logo=windowsterminal&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-7+-0078D6?logo=windows)
![License](https://img.shields.io/badge/License-MIT-blue)

Комплексное управление SMB-ресурсами Windows. Содержит:
- Скрипт отключения административных shares (`disable_smb.bat`)
- Скрипт восстановления (`enable_smb.bat`)

## 🔄 Быстрый старт

### Отключение SMB-ресурсов
```cmd
disable_smb.bat
```

### Восстановление SMB-ресурсов
```cmd
enable_smb.bat
```

## 📌 Скрипт отключения (`disable_smb.bat`)
Отключает:
1. Службу LanmanServer
2. Все административные shares (IPC$, ADMIN$, C$)
3. SMBv1/SMBv2 в реестре
4. Пункт "Общий доступ" в контекстном меню

```batch
:: Пример части кода
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareWks /t REG_DWORD /d 0 /f
```

## ↩️ Скрипт восстановления (`enable_smb.bat`)
Восстанавливает:
1. Службу LanmanServer (автозапуск)
2. Стандартные параметры shares
3. Контекстное меню
4. Перезапускает проводник

```batch
:: Пример части кода
sc config LanmanServer start= auto
start explorer.exe
```

## 🛠 Ручное восстановление
Если скрипты недоступны:
1. Включите службу вручную:
```cmd
sc config LanmanServer start= auto
sc start LanmanServer
```

2. Удалите параметры реестра:
```cmd
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareWks /f
```

## ⚠️ Важно!
- Требуются права Администратора
- Изменения вступают в силу после перезагрузки
- Скрипты автоматически пропускают Windows Server

## 📜 Лицензия
MIT License - [полный текст](LICENSE)
