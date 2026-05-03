@echo off
title Compress to 4MB - FFmpeg

if "%~1"=="" (
    echo.
    echo  Usage: Drag and drop a video file onto this script.
    echo.
    cmd /k
    exit
)

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0components\Compress-To-4MB.ps1" "%~1"
cmd /k
