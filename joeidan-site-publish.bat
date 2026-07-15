@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Joe Idan Website Publisher

rem Run this file from the website folder, next to index.html.
cd /d "%~dp0"

echo.
echo ======================================================
echo       Joe Idan Website - GitHub Publisher
echo ======================================================
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo ERROR: Git is not installed or is not available in PATH.
  echo Install Git for Windows from https://git-scm.com/download/win
  pause
  exit /b 1
)

if not exist "index.html" (
  echo ERROR: index.html was not found in:
  echo %CD%
  echo.
  echo Copy this BAT file into the website folder and run it there.
  pause
  exit /b 1
)

if not exist ".git" goto FIRST_SETUP
goto PUBLISH

:FIRST_SETUP
echo First-time GitHub setup
echo -----------------------
echo Before continuing, create an empty PRIVATE GitHub repository.
echo Recommended name: joeidan-website
echo Do not add a README, .gitignore, or license on GitHub.
echo.
set /p "REPO_URL=Paste the repository URL (https://github.com/...git): "
if not defined REPO_URL (
  echo ERROR: Repository URL is required.
  pause
  exit /b 1
)

git init
if errorlevel 1 goto FAILED
git branch -M main
git remote add origin "%REPO_URL%"
if errorlevel 1 goto FAILED

if not exist ".gitignore" (
  >".gitignore" echo _backups/
  >>".gitignore" echo *.tmp
  >>".gitignore" echo Thumbs.db
)

git add .
git commit -m "Initial import of joeidan.com"
if errorlevel 1 goto FAILED
git push -u origin main
if errorlevel 1 goto FAILED

echo.
echo SUCCESS: The website files are now connected to GitHub.
echo Next, connect this repository to Cloudflare Pages.
pause
exit /b 0

:PUBLISH
echo Creating a local backup...
if not exist "_backups" mkdir "_backups"
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "STAMP=%%I"
powershell -NoProfile -Command "$items=Get-ChildItem -Force ^| Where-Object {$_.Name -notin '.git','_backups'}; Compress-Archive -Path $items.FullName -DestinationPath '_backups\joeidan-site_!STAMP!.zip' -Force"
if errorlevel 1 (
  echo WARNING: Backup creation failed. No files were published.
  pause
  exit /b 1
)

echo.
git status --short
echo.
set /p "MESSAGE=Describe this update (or press Enter for Website update): "
if not defined MESSAGE set "MESSAGE=Website update"

git add .
git diff --cached --quiet
if not errorlevel 1 (
  echo No website changes were found. Nothing was published.
  pause
  exit /b 0
)

git commit -m "%MESSAGE%"
if errorlevel 1 goto FAILED

git pull --rebase origin main
if errorlevel 1 (
  echo.
  echo ERROR: GitHub contains changes that could not be merged automatically.
  echo Nothing was pushed. Ask ChatGPT to help resolve the conflict.
  pause
  exit /b 1
)

git push origin main
if errorlevel 1 goto FAILED

echo.
echo SUCCESS: Changes were pushed to GitHub.
echo If Cloudflare Pages is connected, deployment starts automatically.
echo Open: https://www.joeidan.com
pause
exit /b 0

:FAILED
echo.
echo ERROR: The operation did not complete.
echo Review the message above. No Cloudflare setting was changed.
pause
exit /b 1
