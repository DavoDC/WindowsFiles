@echo off
title FFMPEG Compressor

if "%~1"=="" (
    echo.
    echo  Usage: Drag and drop a video file onto this script.
    echo.
    cmd /k
    exit
)

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0components\FFMPEG-Compressor.ps1" "%~1"
cmd /k
