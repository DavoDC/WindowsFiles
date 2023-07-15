@echo off

set "fpath=C:\Users\%username%\Audio"

dir /b /s "%fpath%\*.mp3" >nul 2>&1
if not errorlevel 1 (
    start "" "C:\Program Files\VideoLAN\VLC\vlc.exe" "%fpath%" --playlist-autostart --no-playlist-tree --auto-preparse --random --loop -Z
    exit
) else (
    echo Audio folder is empty or non-existent!
    pause
)

@REM To fix reading of non-audio file extensions, add the ext to:
@REM Tools -> Prefs -> All -> Playlist -> Ignored extensions