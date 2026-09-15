@echo off
:: =============================================
:: Windows SMB Shares Disabler
:: Version: 2.0
:: Description: Полное отключение SMB-ресурсов
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
    exit /b 1
)

:: --------------------------
:: Проверка на Windows Server
:: --------------------------
wmic os get Caption | find /i "Server" >nul 2>&1
IF NOT ERRORLEVEL 1 (
    echo [INFO] Скрипт пропускает серверные ОС
    exit /b 0
)

:: ====================
:: Основные операции
:: ====================

:: 1. Остановка службы LanmanServer
echo [INFO] Остановка службы LanmanServer...
sc stop LanmanServer >nul 2>&1
sc config LanmanServer start= disabled >nul 2>&1

:: 2. Удаление стандартных ресурсов
echo [INFO] Удаление административных shares...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareWks /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareServer /t REG_DWORD /d 0 /f >nul 2>&1

:: 3. Удаление скрытых shares
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    net share %%d$ >nul 2>&1 && net share %%d$ /delete /y >nul 2>&1
)
net share ADMIN$ /delete /y >nul 2>&1
net share IPC$ /delete /y >nul 2>&1

:: 4. Дополнительные настройки безопасности
echo [INFO] Применение дополнительных настроек...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB1" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB2" /t REG_DWORD /d 0 /f >nul 2>&1

:: 5. Удаление пункта "Общий доступ"
echo [INFO] Отключение пункта "Общий доступ"...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSharingContextMenu /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSharingContextMenu /t REG_DWORD /d 1 /f >nul 2>&1

:: 6. Отключение NTLMv1
echo [INFO] Отключение NTLMv1...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LmCompatibilityLevel" /t REG_DWORD /d 5 /f >nul 2>&1

:: ====================
:: Завершение работы
:: ====================
echo [SUCCESS] Операция завершена успешно!
echo [INFO] Для применения изменений требуется перезагрузка
exit /b 0
