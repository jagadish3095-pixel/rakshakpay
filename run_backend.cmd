@echo off
rem Double-click this file to start the RakshakPay server.
rem It runs run_backend.ps1 without changing Windows' script policy.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_backend.ps1"
pause
