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
    exit /b 1
)

:: --------------------------
:: Проверка на Windows Server
:: --------------------------
wmic os get Caption | find /i "Server" >nul 2>&1
IF NOT ERRORLEVEL 1 (
    echo [INFO] Обнаружена серверная ОС. Восстановление настроек подписывания...
    goto SERVER_CONFIG
)

:: ====================
:: Конфигурация для клиентских ОС
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

:: 5. Восстановление NTLMv1 (возврат к значению по умолчанию)
echo [INFO] Восстановление настроек NTLM...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LmCompatibilityLevel" /t REG_DWORD /d 3 /f >nul 2>&1

:: 6. Сброс обязательного подписывания SMB (Клиент)
echo [INFO] Сброс настроек подписывания SMB...
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "RequireSecuritySignature" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "EnableSecuritySignature" /f >nul 2>&1

:: 7. Сброс обязательного подписывания LDAP
echo [INFO] Сброс настроек подписывания LDAP...
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LDAP" /v "LDAPClientIntegrity" /f >nul 2>&1

:: 8. Восстановление LLMNR (удаление политики)
echo [INFO] Восстановление настроек LLMNR...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /f >nul 2>&1

:: 9. Восстановление NBT-NS (удаление настроек для всех интерфейсов)
echo [INFO] Восстановление настроек NBT-NS...
for /f "tokens=*" %%i in ('wmic nic where "NetEnabled=true" get InterfaceIndex ^| findstr [0-9]') do (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{%%i}" /v "NetbiosOptions" /f >nul 2>&1
)

:: Перезапуск служб для применения настроек
net stop lanmanworkstation /y >nul 2>&1
net start lanmanworkstation >nul 2>&1
ipconfig /flushdns >nul 2>&1
nbtstat -R >nul 2>&1

goto END_CONFIG

:SERVER_CONFIG
:: ====================
:: Восстановление настроек для Windows Server
:: ====================
echo [INFO] Сброс настроек подписывания SMB и LDAP для сервера...

:: SMB Клиент - отмена обязательного подписывания
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "RequireSecuritySignature" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "EnableSecuritySignature" /f >nul 2>&1

:: SMB Сервер - отмена обязательного подписывания
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "RequireSecuritySignature" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "EnableSecuritySignature" /f >nul 2>&1

:: LDAP - сброс подписывания
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LDAP" /v "LDAPClientIntegrity" /f >nul 2>&1

:: Восстановление NTLM (возврат к значению по умолчанию)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LmCompatibilityLevel" /t REG_DWORD /d 3 /f >nul 2>&1

:: Восстановление LLMNR
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /f >nul 2>&1

:: Восстановление NBT-NS
for /f "tokens=*" %%i in ('wmic nic where "NetEnabled=true" get InterfaceIndex ^| findstr [0-9]') do (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{%%i}" /v "NetbiosOptions" /f >nul 2>&1
)

:: Перезапуск служб для применения настроек
net stop lanmanworkstation /y >nul 2>&1
net start lanmanworkstation >nul 2>&1
net stop lanmanserver /y >nul 2>&1
net start lanmanserver >nul 2>&1
ipconfig /flushdns >nul 2>&1
nbtstat -R >nul 2>&1

echo [SUCCESS] Настройки подписывания сброшены для сервера
goto END_CONFIG

:END_CONFIG

:: 6. Перезапуск проводника
echo [INFO] Перезапуск проводника...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe >nul 2>&1

:: ====================
:: Завершение работы
:: ====================
echo [SUCCESS] SMB-ресурсы успешно восстановлены!
echo [INFO] Стандартные shares будут созданы при перезагрузке
exit /b 0
