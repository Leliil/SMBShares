@echo off
:: =============================================
:: Windows SMB Shares Enabler
:: Version: 2.0
:: Description: Восстановление SMB-ресурсов
:: Supported OS: Windows 7/8/10/11 Workstations
:: =============================================

SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

:: --------------------------
:: Проверка прав администратора
:: --------------------------
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Требуются права администратора!
    pause
    exit /b 1
)

:: ====================
:: Основные операции
:: ====================

:: 1. Включение службы LanmanServer
echo [INFO] Включение службы LanmanServer...
sc config LanmanServer start= auto >nul 2>&1
sc start LanmanServer >nul 2>&1

:: 2. Восстановление параметров shares
echo [INFO] Восстановление параметров shares...
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareWks /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareServer /f >nul 2>&1

:: 3. Включение SMB протоколов
echo [INFO] Восстановление SMB-протоколов...
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB1" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB2" /f >nul 2>&1

:: 4. Восстановление контекстного меню
echo [INFO] Восстановление контекстного меню...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSharingContextMenu /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSharingContextMenu /f >nul 2>&1

:: 5. Перезапуск проводника
echo [INFO] Перезапуск проводника...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe >nul 2>&1

:: ====================
:: Завершение работы
:: ====================
echo [SUCCESS] SMB-ресурсы успешно восстановлены!
echo [INFO] Стандартные shares будут созданы при перезагрузке
timeout /t 5 /nobreak >nul
exit /b 0
