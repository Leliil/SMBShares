@echo off
:: Скрипт восстановления SMB-сервера и общих ресурсов
:: Включает службу, разрешает создание shares и возвращает контекстное меню

:: 1. Включение и запуск службы LanmanServer
sc config LanmanServer start= auto >nul 2>&1
sc start LanmanServer >nul 2>&1

:: 2. Разрешение автоматического создания shares
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareWks /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareServer /f >nul 2>&1

:: 3. Включение SMBv1/SMBv2 (опционально)
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB1" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB2" /f >nul 2>&1

:: 4. Восстановление пункта "Общий доступ" в контекстном меню
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSharingContextMenu /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSharingContextMenu /f >nul 2>&1

:: 5. Перезапуск проводника для применения изменений
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe >nul 2>&1

echo [УСПЕХ] SMB-сервер и общие ресурсы восстановлены!
echo Стандартные shares (ADMIN$, C$ и др.) будут созданы при перезагрузке.
pause
