
@echo off
REM Note: Turns off printing of every command

REM Set audio file folder
set fpath="C:\Users\%username%\Audio"

REM If folder is not empty
for /F %%i in ('dir /b "%fpath%\*.*"') do (
   
   REM Play music in folder
   start "" "C:\Program Files\VideoLAN\VLC\vlc.exe" "%fpath%" --playlist-autostart --no-playlist-tree --auto-preparse --random --loop -Z
   exit
   
   goto :EOF
)

REM Else if folder is empty:
REM Notify
echo Audio folder is empty!

REM Pause so user can see
@pause

REM To fix reading of non-audio file ext: Tools -> Prefs -> All -> Playlist -> Ignore ext

