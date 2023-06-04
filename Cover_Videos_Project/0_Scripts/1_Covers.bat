@echo off
setlocal enabledelayedexpansion

REM Clear the console
cls

set "outputFolder=1_Covers"
set "audioFolder=..\0_Audio"
set "coverFolder=..\%outputFolder%"

REM Check if the "Audio" folder exists
if not exist "%audioFolder%" (
    echo "Audio" folder not found.
    pause
    exit /b
)

REM Check if the "Covers" folder exists
if not exist "%coverFolder%" (
    echo "Covers" folder not found.
    pause
    exit /b
)

REM Get the full path of the script directory
set "scriptDir=%~dp0"
set "parentDir=%scriptDir%..\"

REM Set counters for the number of album covers generated and the number of audio files
set "coverCount=0"
set "audioCount=0"

REM Loop through all the MP3 files in the "Audio" folder
for %%F in ("%audioFolder%\*.mp3") do (
    REM Increment the audio file counter
    set /a "audioCount+=1"
    
    REM Extract the filename (without extension) of the MP3 file
    set "filename=%%~nF"
    
    REM Generate the output cover filename
    set "coverFile=%parentDir%%outputFolder%\!filename!_cover.png"

    REM Check if the album cover already exists
    if not exist "!coverFile!" (
        REM Use FFmpeg to extract the album cover image from the MP3 file
        "%scriptDir%ffmpeg.exe" -hide_banner -loglevel error -i "%%F" -an -vcodec copy -y "!coverFile!"
        
        REM Check if the cover image was generated
        if not exist "!coverFile!" (
            echo Album cover was not generated for file: %%F
            pause
            exit /b
        ) else (
            set /a "coverCount+=1"
        )
    ) else (
        echo Album cover already exists for file: !filename!. Skipping generation.
        set /a "coverCount+=1"
    )
)

REM Print the ending message with the count of album covers generated and the count of audio files
echo Album covers generated: %coverCount%/%audioCount%

pause
