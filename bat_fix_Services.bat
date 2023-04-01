

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------



:: Command Info

:: Good Services
SC CONFIG "ulps" START=AUTO
SC CONFIG "W32Time" START=AUTO

:: Unwanted Services
:: - IOBit Services
wmic service where "name like 'AdvancedSystemCareService%'" call ChangeStartmode Disabled
SC CONFIG "IObitUnSvr" START=DISABLED
taskkill /F /IM SmartDefrag.exe
taskkill /F /IM UninstallMonitor.exe

:: - Adobe Updater
wmic service where "name like 'Adobe%'" call ChangeStartmode Disabled
:: - Acronis Clone
SC CONFIG "AGMService" START=DISABLED
SC CONFIG "AGSService" START=DISABLED
:: - AOMEI Backupper
SC CONFIG "Backupper Service" START=DISABLED


:: Bad Services
:: Lanman Server causes explorer hang and crash
SC CONFIG "LanmanServer" START=DISABLED

:: Disables Windows Update
SC CONFIG "SU10Guard" START=DISABLED


:: Add:
:: stop origin, parsec and teamviewer!
