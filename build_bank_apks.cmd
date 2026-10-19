@echo off
rem Double-click this file to build all 5 bank APKs into the dist folder.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_bank_apks.ps1"
pause
