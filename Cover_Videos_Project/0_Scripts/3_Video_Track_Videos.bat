@echo off
setlocal enabledelayedexpansion

REM Create the FIXED_VIDS folder if it doesn't exist
mkdir "FIXED_VIDS" 2>nul

REM Loop through each video file in the OLD_VIDS folder
for %%F in ("OLD_VIDS\*.mp4") do (
  REM Get the filename without extension
  set "filename=%%~nF"
  
  REM Set the corresponding audio and image paths
  set "audio=AUDIO\!filename!.mp3"
  set "image=COVERS\!filename!_image.png"
  
  REM Run ffmpeg to fix the video with lower preset and adjusted bitrate
  ffmpeg -y -loop 1 -i "!image!" -i "!audio!" -c:v libx264 -preset slower -tune stillimage -c:a copy -pix_fmt yuv420p -b:v 1M -t 300 "FIXED_VIDS\!filename!.mp4"
)

echo Videos have been fixed and placed in the FIXED_VIDS folder.
endlocal
