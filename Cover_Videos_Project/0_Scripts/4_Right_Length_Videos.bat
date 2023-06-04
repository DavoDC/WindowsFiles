@echo off
echo Not implemented/working. See comment.
pause

@REM WARNING
@REM Never managed to fix this one.
@REM Couldn't pass duration to ffmpeg correctly.
@REM Also needs to be converted to seconds format (e.g. -t 120 for 2 minutes)



@REM @echo off
@REM setlocal enabledelayedexpansion

@REM set "durations_folder=DURATIONS"
@REM set "videos_folder=VIDS"
@REM set "trimmed_folder=TRIMMED"

@REM if not exist "%trimmed_folder%" mkdir "%trimmed_folder%"

@REM for %%A in ("%videos_folder%\*.mp4") do (
@REM     set "video_filepath=%%A"
@REM     set "video_filename=%%~nxA"

@REM     REM Get duration from ffprobe

@REM     REM Generate the trimmed file path
@REM     set "trimmed_file=!trimmed_folder!\!video_filename!"

@REM     REM Echo the duration
@REM     echo.
@REM     echo DURATION BEING USED: "!formatted_duration!"
@REM     echo.

@REM     REM Trim the video using FFmpeg
@REM     ffmpeg -ss 0 -i "!video_filepath!" "!formatted_duration!" "!trimmed_file!.mp4"

@REM     REM Check if the trimmed file was created
@REM     if not exist "!trimmed_file!.mp4" (
@REM         echo No MP4 file was added to the TRIMMED folder.
@REM         echo Script will now stop.
@REM         pause
@REM         exit /b
@REM     )
@REM )

@REM echo Videos have been trimmed.

@REM endlocal
@REM pause
