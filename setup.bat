@echo off
title Setup Supabase Environment Variables
color 0E
cls

echo.
echo 🔧 ============================================
echo    SETUP SUPABASE ENVIRONMENT VARIABLES
echo    ============================================
echo.

echo This will help you configure your Supabase credentials.
echo.
echo You need:
echo 1. Your Supabase Project URL (e.g., https://abc123.supabase.co)
echo 2. Your Supabase Anon Key (from Settings > API in your dashboard)
echo.

set /p supabase_url="Enter your Supabase URL: "
if "%supabase_url%"=="" (
    echo ❌ URL cannot be empty
    pause
    exit /b 1
)

set /p supabase_key="Enter your Supabase Anon Key: "
if "%supabase_key%"=="" (
    echo ❌ Key cannot be empty
    pause
    exit /b 1
)

echo.
echo Setting environment variables...

REM Set for current session
set VITE_SUPABASE_URL=%supabase_url%
set VITE_SUPABASE_ANON_KEY=%supabase_key%

REM Set permanently for user
setx VITE_SUPABASE_URL "%supabase_url%" >nul
setx VITE_SUPABASE_ANON_KEY "%supabase_key%" >nul

echo.
echo ✅ Environment variables configured!
echo.
echo 📋 Current session variables:
echo    URL: %VITE_SUPABASE_URL%
echo    Key: %VITE_SUPABASE_ANON_KEY:~0,20%...
echo.
echo ⚠️  Note: New terminals will need to be restarted to see the permanent variables
echo.
echo 🚀 You can now run: start.bat
echo.
pause