@echo off
setlocal enabledelayedexpansion

REM Loop through all the MP3 files in the "MP3_Files" folder
for %%M in ("%~dp0MP3_Files\*.mp3") do (
    REM Get the file name of the MP3 file
    set "fileName=%%~nM"

    REM Check if a corresponding image file exists in the "Covers" folder
    if exist "%~dp0Covers\!fileName!_image.png" (
        set "image=%~dp0Covers\!fileName!_image.png"

        REM Convert mp3 to mp4
        set "outputFile=%~dp0ConvertedVideos\!fileName!_AudioVideo.mp4"
        if exist "!outputFile!" (
            echo File '!outputFile!' already exists. Skipping.
        ) else (
            REM Print the image file path
            echo Image file used: !image!

            "%~dp0ffmpeg.exe" -loop 1 -i "!image!" -i "%%M" -map 0 -map 1 -c copy -shortest -pix_fmt yuv420p "!outputFile!"
        )
    ) else (
        echo Image file for '%%~dpnM' not found. Skipping.
    )
)

echo All MP4 files generated successfully.
