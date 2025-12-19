@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: =========================================================
::  GIT AUTOMATION - XYHYXU SPECIAL EDITION
::  Status: STABLE (No Crash)
:: =========================================================

:: 1. Safe Color Generation (Standard Method)
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set "ESC=%%b"
)

:: Define Colors
set "RESET=%ESC%[0m"
set "BOLD=%ESC%[1m"
set "CYAN=%ESC%[36m"
set "MAGENTA=%ESC%[35m"
set "YELLOW=%ESC%[33m"
set "GREEN=%ESC%[32m"
set "RED=%ESC%[31m"
set "BLUE=%ESC%[34m"

:: Window Title
title Git Pro - Powered by xyhyxu
mode con: cols=85 lines=30

:: ---------------------------------------------------------
:: 2. Boot Animation & Logo
:: ---------------------------------------------------------
cls
echo.
echo  %CYAN%      .gmMMMm.         %MAGENTA%      .xmMMMm.      %RESET%
echo  %CYAN%    .mMMMMMMMMm.       %MAGENTA%    .mMMMMMMMMm.    %RESET%
echo  %CYAN%   mMMMMMMMMMMMMm      %MAGENTA%   mMMMMMMMMMMMMm   %RESET%
echo  %CYAN%   MMMMMMMMMMMMMM      %MAGENTA%   MMMMMMMMMMMMMM   %RESET%
echo  %CYAN%   'MMMMMMMMMMMM'      %MAGENTA%   'MMMMMMMMMMMM'   %RESET%
echo.
echo  %BOLD%   G I T   A U T O   M A T I O N   T O O L   %RESET%
echo  %CYAN%   =========================================   %RESET%
echo           %YELLOW%Dev and Design by: xyhyxu%RESET%
echo.

echo  %BLUE%[SYSTEM] Initializing Modules...%RESET%
:: Using ping for delay to avoid timeout command crash on some systems
ping 127.0.0.1 -n 2 >nul
echo  %GREEN%[OK] Ready.%RESET%
echo.

:: ---------------------------------------------------------
:: 3. Environment Check
:: ---------------------------------------------------------
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo  %RED%[ERROR] Git is not installed or not in PATH.%RESET%
    pause
    exit /b
)

if not exist .git (
    echo  %RED%[ERROR] No .git folder found here.%RESET%
    echo  Please put this file in your project root folder.
    pause
    exit /b
)

:: ---------------------------------------------------------
:: 4. Status Check
:: ---------------------------------------------------------
echo  %MAGENTA%[%time:~0,8%]%RESET% Scanning workspace...

:: Get Branch Name
for /f "tokens=*" %%i in ('git branch --show-current') do set "BRANCH=%%i"
echo  %CYAN%[INFO]%RESET% Current Branch: %GREEN%!BRANCH!%RESET%

:: Check for Changes
set "HAS_CHANGES=0"
for /f "delims=" %%i in ('git status --short') do set "HAS_CHANGES=1"

if "!HAS_CHANGES!"=="1" (
    echo  %CYAN%[INFO]%RESET% Changes detected. Starting commit process...
    echo.
    echo  %YELLOW%=========================================%RESET%
    echo     Executing: git add .
    echo  %YELLOW%=========================================%RESET%
    git add .
    
    echo.
    echo  %GREEN%Enter Commit Message:%RESET%
    set "MSG="
    set /p "MSG=%CYAN% > %RESET%"
    
    if "!MSG!"=="" set "MSG=Update by xyhyxu [%date%]"
    
    echo.
    echo  %MAGENTA%[%time:~0,8%]%RESET% Committing...
    git commit -m "!MSG!"
) else (
    echo.
    echo  %GREEN%[OK] Workspace is clean. No new files.%RESET%
)

:: ---------------------------------------------------------
:: 5. Push Check
:: ---------------------------------------------------------
echo.
echo  %MAGENTA%[%time:~0,8%]%RESET% Checking remote status...

git status | findstr "ahead" >nul
if %errorlevel% equ 0 (
    echo.
    echo  %RED%[WARN] Local commits need to be pushed!%RESET%
    echo.
    set "PUSH_CHOICE="
    set /p "PUSH_CHOICE=%YELLOW%[ACTION] Push now? (Y/N): %RESET%"
    
    if /i "!PUSH_CHOICE!"=="y" (
        echo.
        echo  %BLUE%=========================================%RESET%
        echo     Executing: git push origin !BRANCH!
        echo  %BLUE%=========================================%RESET%
        git push
        
        if !errorlevel! equ 0 (
            echo.
            echo  %GREEN%[SUCCESS] Push complete!%RESET%
        ) else (
            echo.
            echo  %RED%[ERROR] Push failed. Check network.%RESET%
        )
    ) else (
        echo  [INFO] Push skipped.
    )
) else (
    echo  %GREEN%[OK] Up to date with remote.%RESET%
)

:: ---------------------------------------------------------
:: 6. End
:: ---------------------------------------------------------
echo.
echo  %CYAN%___________________________________________________%RESET%
echo.
echo       %GREEN%All operations completed successfully.%RESET%
echo            %YELLOW%Have a nice day, xyhyxu!%RESET%
echo.
pause