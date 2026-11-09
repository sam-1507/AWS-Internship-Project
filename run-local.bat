@echo off
title AWS Student Portal - Local Server
echo ========================================================
echo Starting Student Portal Local Server...
echo ========================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-local.ps1"
pause
