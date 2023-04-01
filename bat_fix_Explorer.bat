@echo off
echo.
echo "Explorer will be restarted"
echo.

echo "taskkill /F /IM explorer.exe"
taskkill /F /IM explorer.exe
echo.

echo "start explorer.exe"
start explorer.exe
echo.

echo.
@pause
