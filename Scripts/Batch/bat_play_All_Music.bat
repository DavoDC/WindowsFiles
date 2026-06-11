@echo off

set "audioPath=C:\Users\%username%\Audio"
set "vlcpath1=C:\Program Files\VideoLAN\VLC\vlc.exe"
set "vlcpath2=C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"
set "vlcpath="
set "playlist=%TEMP%\all_music_shuffled.m3u"

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

:: Check audio folder exists
if not exist "%audioPath%" (
    echo.
    echo Audio folder not found: %audioPath%
    echo.
    pause
    exit /b
)

:: NOTE: Library is MP3-only - do not add other formats (.flac, .wav, .m4a etc)
:: Build a flat shuffled M3U using PowerShell - bypasses VLC's folder-biased shuffle
:: Sort-Object {Get-Random} works on PS5 (built-in Windows) and PS7
echo Building shuffled playlist from full library...
powershell -NoProfile -Command "$f=Get-ChildItem -LiteralPath '%audioPath%' -Recurse -Include '*.mp3' | Sort-Object {Get-Random}; '#EXTM3U' | Set-Content -LiteralPath '%playlist%' -Encoding UTF8; $f.FullName | Add-Content -LiteralPath '%playlist%' -Encoding UTF8; Write-Host ($f.Count.ToString() + ' tracks - playlist ready')"

if errorlevel 1 (
    echo.
    echo Failed to build playlist!
    echo.
    pause
    exit /b
)

:: Kill any existing VLC for a clean start
taskkill /f /im vlc.exe >nul 2>&1

:: Launch VLC with pre-shuffled flat playlist
:: -L loops; -Z adds re-shuffle between loops; no recursive scan needed
start "" "%vlcpath%" "%playlist%" --playlist-autostart -L -Z --no-auto-preparse --no-metadata-network-access
exit /b

:: To fix reading of non-audio file extensions, add the ext to:
:: Tools -> Prefs -> All -> Playlist -> Ignored extensions
::
:: If VLC behaves erratically (wrong playlist, slow start), rebuild the plugin cache:
:: Run as admin: "C:\Program Files\VideoLAN\VLC\vlc-cache-gen.exe" "C:\Program Files\VideoLAN\VLC\plugins"
