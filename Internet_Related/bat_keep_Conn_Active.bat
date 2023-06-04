
@echo off
REM The above prevents the comments from outputting when script is run

REM Pings default gateway regularly
REM Keeps connection active
REM Prevents powerline adapter from turning off

REM Adjust packet size
SET size=1

REM Adjust delay between pings
REM SET delay=7
 
REM  :loop
REM  ping -l %size% 192.168.0.1
REM  timeout /t %delay%
REM  goto loop


REM Repeat with no delay
ping -t -l %size% 192.168.0.1