@echo off

set "audioPath=C:\Users\%username%\Audio"
set "vlcpath1=C:\Program Files\VideoLAN\VLC\vlc.exe"
set "vlcpath2=C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"
set "vlcpath="

:: Find VLC installation path
if exist "%vlcpath1%" (
    set "vlcpath=%vlcpath1%"
) else if exist "%vlcpath2%" (
    set "vlcpath=%vlcpath2%"
) else (
    echo.
    echo VLC is not installed or cannot be found!
    echo.
    pause
    exit /b
)

:: Check if audio folder contains MP3 files
dir /b /s "%audioPath%\*.mp3" >nul 2>&1
if errorlevel 1 (
    echo.
    echo Audio folder is empty or non-existent!
    echo.
    pause
    exit /b
)

:: Kill any existing VLC to guarantee a clean start (prevents "stuck on previous session" issue)
taskkill /f /im vlc.exe >nul 2>&1

:: Launch VLC
:: -Z                       Shuffle (random forever) - replaces redundant --random + -Z combo
:: -L                       Loop playlist
:: --no-auto-preparse       Skip upfront metadata scan - the main cause of slow startup
:: --no-metadata-network-access  Block online metadata lookups (another startup delay)
:: --recursive=expand       Explicitly scan all subdirectories
:: --no-playlist-tree       Flat list view
:: --playlist-autostart     Begin playback immediately on load
start "" "%vlcpath%" "%audioPath%" --no-playlist-tree --playlist-autostart -Z -L --no-auto-preparse --no-metadata-network-access --recursive=expand
exit /b

:: To fix reading of non-audio file extensions, add the ext to:
:: Tools -> Prefs -> All -> Playlist -> Ignored extensions