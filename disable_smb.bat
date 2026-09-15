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
    echo [INFO] Обнаружена серверная ОС. Применение настроек подписывания...
    goto SERVER_CONFIG
)

:: ====================
:: Конфигурация для клиентских ОС
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
    net share %%d$ /delete /y >nul 2>&1
)
net share ADMIN$ /delete /y >nul 2>&1
net share IPC$ /delete /y >nul 2>&1

:: 4. Отключение SMBv1, SMBv2 и SMBv3
echo [INFO] Применение дополнительных настроек...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB1" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB2" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB3" /t REG_DWORD /d 0 /f >nul 2>&1

:: 5. Удаление пункта "Общий доступ"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSharingContextMenu /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSharingContextMenu /t REG_DWORD /d 1 /f >nul 2>&1

:: 6. Отключение NTLMv1
echo [INFO] Отключение NTLMv1...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LmCompatibilityLevel" /t REG_DWORD /d 5 /f >nul 2>&1

:: 7. Обязательное подписывание SMB (Клиент)
echo [INFO] Включение обязательного подписывания SMB...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "RequireSecuritySignature" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "EnableSecuritySignature" /t REG_DWORD /d 1 /f >nul 2>&1

:: 8. Обязательное подписывание LDAP
echo [INFO] Включение обязательного подписывания LDAP...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LDAP" /v "LDAPClientIntegrity" /t REG_DWORD /d 2 /f >nul 2>&1

:: 9. Отключение LLMNR (Link-Local Multicast Name Resolution)
echo [INFO] Отключение LLMNR...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d 0 /f >nul 2>&1

:: 10. Отключение NBT-NS (NetBIOS over TCP/IP)
echo [INFO] Отключение NBT-NS...
for /f "tokens=*" %%i in ('wmic nic where "NetEnabled=true" get InterfaceIndex ^| findstr [0-9]') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{%%i}" /v "NetbiosOptions" /t REG_DWORD /d 2 /f >nul 2>&1
)

:: Перезапуск служб для применения настроек
net stop lanmanworkstation /y >nul 2>&1
net start lanmanworkstation >nul 2>&1
ipconfig /flushdns >nul 2>&1
nbtstat -R >nul 2>&1

goto END_CONFIG

:SERVER_CONFIG
:: ====================
:: Конфигурация для Windows Server
:: ====================
echo [INFO] Настройка подписывания SMB и LDAP для сервера...

:: SMB Клиент - обязательное подписывание
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "RequireSecuritySignature" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "EnableSecuritySignature" /t REG_DWORD /d 1 /f >nul 2>&1

:: SMB Сервер - обязательное подписывание
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "RequireSecuritySignature" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "EnableSecuritySignature" /t REG_DWORD /d 1 /f >nul 2>&1

:: LDAP - обязательное подписывание
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LDAP" /v "LDAPClientIntegrity" /t REG_DWORD /d 2 /f >nul 2>&1

:: Отключение NTLMv1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LmCompatibilityLevel" /t REG_DWORD /d 5 /f >nul 2>&1

:: Отключение LLMNR
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d 0 /f >nul 2>&1

:: Отключение NBT-NS для всех активных интерфейсов
for /f "tokens=*" %%i in ('wmic nic where "NetEnabled=true" get InterfaceIndex ^| findstr [0-9]') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{%%i}" /v "NetbiosOptions" /t REG_DWORD /d 2 /f >nul 2>&1
)

:: Перезапуск служб для применения настроек
net stop lanmanworkstation /y >nul 2>&1
net start lanmanworkstation >nul 2>&1
net stop lanmanserver /y >nul 2>&1
net start lanmanserver >nul 2>&1
ipconfig /flushdns >nul 2>&1
nbtstat -R >nul 2>&1

echo [SUCCESS] Настройки подписывания применены для сервера
goto END_CONFIG

:END_CONFIG

:: ====================
:: Завершение работы
:: ====================
echo [SUCCESS] Операция завершена успешно!
echo [INFO] Для применения изменений требуется перезагрузка
exit /b 0
