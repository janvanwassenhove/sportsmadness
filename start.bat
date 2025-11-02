@echo off
title Hockey Madness - Start Application
color 0A
cls

echo.
echo 🏒 ========================================
echo    HOCKEY MADNESS - START APPLICATION
echo    ========================================
echo.

REM Check if we're in the correct directory
if not exist "apps\frontend" (
    echo ❌ Please run this from the hockeymadness root directory
    pause
    exit /b 1
)

REM Check Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Node.js not found. Please install Node.js 18+ first.
    echo    Download from: https://nodejs.org/
    pause
    exit /b 1
)

echo ✅ Node.js found: 
node --version

echo.
echo 🔍 Checking Supabase configuration...

REM Force refresh system environment variables
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v VITE_SUPABASE_URL 2^>nul') do set VITE_SUPABASE_URL=%%B
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v VITE_SUPABASE_ANON_KEY 2^>nul') do set VITE_SUPABASE_ANON_KEY=%%B

REM Check system environment variables first (priority)
if defined VITE_SUPABASE_URL goto :use_system_vars

echo ⚠️  System environment variables not found
echo    Checking .env.local file...

cd apps\frontend
if not exist ".env.local" goto :use_defaults

findstr /v "^#" .env.local | findstr "VITE_SUPABASE_URL" >nul 2>nul
if %errorlevel% neq 0 goto :use_defaults

echo ✅ Using .env.local file configuration
set CONFIG_SOURCE=.env.local file
cd ..\..
goto :start_app

:use_system_vars
echo ✅ Using SYSTEM environment variables
echo    URL: %VITE_SUPABASE_URL%
echo    Key: %VITE_SUPABASE_ANON_KEY:~0,20%...
set CONFIG_SOURCE=System Environment Variables
goto :start_app

:use_defaults
echo ⚠️  Using default local Supabase configuration
echo    URL: http://localhost:54321
set CONFIG_SOURCE=Default local Supabase
if exist ".env.local" cd ..\..
goto :start_app

:start_app

echo.
echo 📦 Installing dependencies...
cd apps\frontend

if not exist "node_modules" (
    echo    Installing frontend dependencies...
    call npm install
    if %errorlevel% neq 0 (
        echo ❌ Failed to install dependencies
        pause
        exit /b 1
    )
    echo ✅ Dependencies installed
) else (
    echo ✅ Dependencies already installed
)

echo.
echo 🚀 Starting Hockey Madness...
echo    Configuration: %CONFIG_SOURCE%
echo    Frontend: http://localhost:5173
echo.
echo 💡 Tips:
echo    - Press Ctrl+C to stop the application
echo    - Check browser console for detailed config info
echo    - Login at /login, then visit /admin for management

call npm run dev

cd ..\..
echo.
echo 👋 Hockey Madness stopped
pause