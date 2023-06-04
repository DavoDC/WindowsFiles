@echo off
setlocal

set "parent_directory=.."
set "folders=0_Audio 0_Scripts 1_Covers 2_RawVideos 3_VideoTrackVideos 4_VideosWithRightLength"
set "missing_folder="
set "problem=0"

for %%F in (%folders%) do (
    if not exist "%parent_directory%\%%F\" (
        set "missing_folder=%%F"
        set "problem=1"
    )
)

if "%missing_folder%" neq "" (
    echo Folder missing in the parent directory: %missing_folder%
    set "problem=1"
) 

if not exist "%parent_directory%\0_Audio\*.mp3" (
    echo No MP3 files found in the Audio folder.
    set "problem=1"
)

if not exist "%parent_directory%\0_Scripts\ffmpeg.exe" (
    echo ffmpeg.exe is missing in the Scripts folder.
    set "problem=1"
)

if not exist "%parent_directory%\0_Scripts\ffprobe.exe" (
    echo ffprobe.exe is missing in the Scripts folder.
    set "problem=1"
)

if "%problem%"=="1" (
    echo "There is a problem! :O"
) else (
    echo "All checks passed! :)"
)

pause
exit
