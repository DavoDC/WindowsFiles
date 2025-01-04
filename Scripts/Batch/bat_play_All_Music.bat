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
    echo "VLC is not installed or cannot be found!"
    echo.
    pause
    exit /b
)

:: Check if audio folder contains MP3 files
dir /b /s "%audioPath%\*.mp3" >nul 2>&1
if errorlevel 1 (
    echo.
    echo "Audio folder is empty or non-existent!"
    echo.
    pause
    exit /b
)

:: Launch VLC with specified options
:: --no-playlist-tree - Disables hierarchical grouping and expands all items into a flat list.
:: --playlist-autostart - Automatically starts playing the playlist.
:: --auto-preparse - Pre-parses metadata for media files in the playlist before they are played.
:: --random - Shuffles the playlist.
:: --loop - Loops the playlist continuously.
:: -Z - Enables random and loop together (shuffled loop).
start "" "%vlcpath%" "%audioPath%" --no-playlist-tree --playlist-autostart --auto-preparse --random --loop -Z
exit /b

:: To fix reading of non-audio file extensions, add the ext to:
:: Tools -> Prefs -> All -> Playlist -> Ignored extensions