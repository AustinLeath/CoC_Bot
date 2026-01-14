@echo off
echo Starting all CoC Bot instances...

echo Starting instance: TheLethalLeaf2
start "CoC_Bot_TheLethalLeaf2" cmd /c "cd /d %~dp0.. && python src\main.py --id ""TheLethalLeaf2"""
timeout /t 2 /nobreak > nul

echo Starting instance: NBBoss
start "CoC_Bot_NBBoss" cmd /c "cd /d %~dp0.. && python src\main.py --id NBBoss"
timeout /t 2 /nobreak > nul

echo Starting instance: ChaosRushed
start "CoC_Bot_ChaosRushed" cmd /c "cd /d %~dp0.. && python src\main.py --id ChaosRushed"
timeout /t 2 /nobreak > nul

echo All instances started.
echo Use Task Manager to monitor and stop individual instances if needed.
pause
