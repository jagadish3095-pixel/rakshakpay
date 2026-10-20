@echo off
rem Double-click to build release APKs of all 9 apps into the dist folder.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_all_apks.ps1" %*
pause
