@echo off
echo Starting all CoC Bot instances...

echo Starting instance: Clash1
start "CoC_Bot_Clash1" cmd /c "cd /d %~dp0.. && python src\main.py --id Clash1"
timeout /t 1 /nobreak > nul

echo Starting instance: Clash2
start "CoC_Bot_Clash2" cmd /c "cd /d %~dp0.. && python src\main.py --id Clash2"
timeout /t 1 /nobreak > nul

echo Starting instance: Clash3
start "CoC_Bot_Clash3" cmd /c "cd /d %~dp0.. && python src\main.py --id Clash3"
timeout /t 1 /nobreak > nul

echo Starting instance: Clash4
start "CoC_Bot_Clash4" cmd /c "cd /d %~dp0.. && python src\main.py --id Clash4"
timeout /t 1 /nobreak > nul

echo Starting instance: Clash5
start "CoC_Bot_Clash5" cmd /c "cd /d %~dp0.. && python src\main.py --id Clash5"
timeout /t 1 /nobreak > nul

echo Starting instance: Clash6
start "CoC_Bot_Clash6" cmd /c "cd /d %~dp0.. && python src\main.py --id Clash6"
timeout /t 1 /nobreak > nul

echo All instances started.
echo Use Task Manager to monitor and stop individual instances if needed.
pause
