@echo off
:: Скрипт для полного отключения всех SMB-ресурсов (IPC$, ADMIN$ и других) на рабочих станциях
:: Автоматически пропускает серверы Windows (Server 2008+)
:: Работает в тихом режиме (без вывода в консоль)

:: Проверка, является ли система сервером
for /f "tokens=4-5 delims=[]. " %%i in ('ver') do (
    if /i "%%i"=="Server" (
        exit /b 0
    )
)

:: 1. Остановка и отключение службы LanmanServer
sc stop LanmanServer >nul 2>&1
sc config LanmanServer start= disabled >nul 2>&1

:: 2. Удаление ВСЕХ стандартных общих ресурсов (IPC$, ADMIN$, C$ и т.д.)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareWks /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareServer /t REG_DWORD /d 0 /f >nul 2>&1

:: 3. Принудительное удаление скрытых административных shares (ADMIN$, C$, D$ и др.)
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    net share %%d$ /delete /y >nul 2>&1
)
net share ADMIN$ /delete /y >nul 2>&1
net share IPC$ /delete /y >nul 2>&1

:: 4. Запрет повторного создания shares при перезагрузке
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB1" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB2" /t REG_DWORD /d 0 /f >nul 2>&1

:: 5. (Опционально) Удаление пункта "Общий доступ" из контекстного меню
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSharingContextMenu /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSharingContextMenu /t REG_DWORD /d 1 /f >nul 2>&1
exit /b 0
