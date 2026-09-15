@echo off
:: Скрипт для полного отключения SMB-ресурсов и усиления безопасности
:: Автоматически пропускает серверы Windows
:: Работает в тихом режиме (без вывода в консоль)

:: 1. Проверка, является ли система сервером (используем systeminfo для надежности)
systeminfo | findstr /i "Server" >nul 2>&1
if not errorlevel 1 exit /b 0

:: 2. Отключение NTLMv1 (только NTLMv2)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LmCompatibilityLevel" /t REG_DWORD /d 5 /f >nul 2>&1

:: 3. Принудительное подписывание SMB (Клиент и Сервер)
:: Клиент
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "RequireSecuritySignature" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "EnableSecuritySignature" /t REG_DWORD /d 1 /f >nul 2>&1
:: Сервер (параметры применяются, даже если служба будет остановлена)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "RequireSecuritySignature" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "EnableSecuritySignature" /t REG_DWORD /d 1 /f >nul 2>&1

:: 4. Принудительное подписывание LDAP
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LDAP" /v "LDAPClientIntegrity" /t REG_DWORD /d 2 /f >nul 2>&1

:: 5. Отключение LLMNR (Group Policy и реестр)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d 0 /f >nul 2>&1

:: 6. Отключение NBT-NS на всех интерфейсах
for /f "tokens=*" %%i in ('wmic nic where "NetEnabled=true" get InterfaceIndex ^| findstr [0-9]') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{%%i}" /v "NetbiosOptions" /t REG_DWORD /d 2 /f >nul 2>&1
)
:: Примечание: полный сброс NetbiosOptions требует перезагрузки или переподключения сети, 
:: но установка значения 2 (отключено) является стандартом безопасности.

:: 7. Остановка и отключение службы LanmanServer (SMB Server)
sc stop LanmanServer >nul 2>&1
sc config LanmanServer start= disabled >nul 2>&1

:: 8. Запрет автоматического создания административных шар (AutoShareWks)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareWks /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareServer /t REG_DWORD /d 0 /f >nul 2>&1

:: 9. Принудительное удаление существующих скрытых шар
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    net share %%d$ /delete /y >nul 2>&1
)
net share ADMIN$ /delete /y >nul 2>&1
net share IPC$ /delete /y >nul 2>&1
net share C$ /delete /y >nul 2>&1

:: 10. Отключение SMBv1 (дополнительная защита, хотя служба выше остановлена)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB1" /t REG_DWORD /d 0 /f >nul 2>&1

:: 11. Удаление пункта "Общий доступ" из контекстного меню
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSharingContextMenu /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSharingContextMenu /t REG_DWORD /d 1 /f >nul 2>&1

:: 12. Перезапуск службы LanmanWorkstation для применения настроек подписывания
net stop lanmanworkstation /y >nul 2>&1
net start lanmanworkstation >nul 2>&1

exit /b 0
