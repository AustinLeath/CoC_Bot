@echo off
setlocal

set /p INSTANCE_ID="Enter instance ID: "

set BASE_NAME=CoC_Bot
set SESSION_NAME=%BASE_NAME%_%INSTANCE_ID%

echo Starting CoC Bot instance: %INSTANCE_ID%
echo Using ADB address for instance: %INSTANCE_ID%

cd /d %~dp0..
python src\main.py --id %INSTANCE_ID%

pause
