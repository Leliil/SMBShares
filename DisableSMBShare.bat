@echo off
:: ===================================================================
:: DisableSMBShare.bat
:: Назначение: Отключение SMB-ресурсов на клиентских ОС и применение
::             политик безопасности (подписывание, NTLMv2, LLMNR off)
::             на всех ОС (клиенты и серверы).
:: Режим: Silent (без вывода в консоль), для удаленного выполнения.
:: ===================================================================

:: 1. Определение типа ОС (Сервер или Клиент)
:: Используем systeminfo для надежного определения "Server" в названии
set "IS_SERVER=0"
systeminfo | findstr /i "Server" >nul 2>&1
if %errorlevel% equ 0 set "IS_SERVER=1"

:: Если это сервер, переходим к блоку настройки безопасности (пропуская отключение службы)
if %IS_SERVER% equ 1 goto SERVER_SECURITY_CONFIG

:: ===================================================================
:: БЛОК ДЛЯ КЛИЕНТСКИХ ОС (Workstations)
:: Полное отключение функции файлового сервера
:: ===================================================================

:: 1. Остановка и отключение службы LanmanServer (SMB Server)
sc stop LanmanServer >nul 2>&1
sc config LanmanServer start= disabled >nul 2>&1

:: 2. Запрет автоматического создания административных шаров (AutoShareWks)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareWks /t REG_DWORD /d 0 /f >nul 2>&1

:: 3. Принудительное удаление текущих скрытых шаров (C$, D$, ADMIN$, IPC$)
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    net share %%d$ /delete /y >nul 2>&1
)
net share ADMIN$ /delete /y >nul 2>&1
net share IPC$ /delete /y >nul 2>&1

:: 4. Отключение SMBv1 (дополнительная защита, хотя служба уже остановлена)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB1" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB2" /t REG_DWORD /d 0 /f >nul 2>&1

:: 5. Удаление пункта "Общий доступ" из контекстного меню проводника
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSharingContextMenu /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSharingContextMenu /t REG_DWORD /d 1 /f >nul 2>&1

:: Переход к общим настройкам безопасности (применяются и там, и там)
goto COMMON_SECURITY_CONFIG

:: ===================================================================
:: БЛОК ДЛЯ СЕРВЕРНЫХ ОС (Windows Server)
:: Служба LanmanServer НЕ отключается, применяются только политики
:: ===================================================================
:SERVER_SECURITY_CONFIG

:: 1. Принудительное подписывание SMB (Серверная часть)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "RequireSecuritySignature" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "EnableSecuritySignature" /t REG_DWORD /d 1 /f >nul 2>&1

:: 2. Принудительное подписывание SMB (Клиентская часть - для исходящих подключений с сервера)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "RequireSecuritySignature" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "EnableSecuritySignature" /t REG_DWORD /d 1 /f >nul 2>&1

:: 3. Перезапуск служб SMB для применения настроек подписывания
net stop lanmanserver /y >nul 2>&1
net start lanmanserver >nul 2>&1
net stop lanmanworkstation /y >nul 2>&1
net start lanmanworkstation >nul 2>&1

:: ===================================================================
:: ОБЩИЕ НАСТРОЙКИ БЕЗОПАСНОСТИ (Применяются на ВСЕХ ОС)
:: ===================================================================
:COMMON_SECURITY_CONFIG

:: 1. Отключение NTLMv1 (Разрешить только NTLMv2)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LmCompatibilityLevel" /t REG_DWORD /d 5 /f >nul 2>&1

:: 2. Отключение LLMNR (Link-Local Multicast Name Resolution)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d 0 /f >nul 2>&1

:: 3. Отключение NBT-NS (NetBIOS over TCP/IP) на всех интерфейсах
:: Напрямую через реестр адаптеров
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /f "Name" ^| findstr "HKEY"') do (
    reg add "%%a" /v "NetbiosOptions" /t REG_DWORD /d 2 /f >nul 2>&1
)

:: 4. Отключение службы TCP/IP NetBIOS Helper
sc stop LmHosts >nul 2>&1
sc config LmHosts start= disabled >nul 2>&1

:: 5. Очистка кэша DNS и NetBIOS
ipconfig /flushdns >nul 2>&1
nbtstat -R >nul 2>&1

exit /b 0
