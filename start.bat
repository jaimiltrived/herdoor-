@echo off
title HerDoor - Backend Server
color 0A

echo ============================================
echo    HerDoor Backend Startup Script
echo ============================================
echo.

:: Step 1: Start MySQL if not running
echo [1/3] Checking MySQL...
tasklist /FI "IMAGENAME eq mysqld.exe" 2>NUL | find /I "mysqld.exe" >NUL
if %ERRORLEVEL%==0 (
    echo       MySQL is already running.
) else (
    echo       Starting MySQL...
    start "" /B "C:\xampp\mysql\bin\mysqld.exe" --defaults-file="C:\xampp\mysql\bin\my.ini" --skip-slave-start
    timeout /t 5 /nobreak >NUL
    echo       MySQL started on port 3307.
)
echo.

:: Step 2: Start Apache if not running
echo [2/3] Checking Apache...
tasklist /FI "IMAGENAME eq httpd.exe" 2>NUL | find /I "httpd.exe" >NUL
if %ERRORLEVEL%==0 (
    echo       Apache is already running.
) else (
    echo       Starting Apache...
    start "" /B "C:\xampp\apache\bin\httpd.exe"
    timeout /t 2 /nobreak >NUL
    echo       Apache started on port 80.
)
echo.

:: Step 3: Start Node.js backend
echo [3/3] Starting HerDoor Backend...
echo.
echo ============================================
echo    MySQL:      port 3307
echo    phpMyAdmin: http://localhost/phpmyadmin
echo    API Server: http://localhost:5000
echo    Health:     http://localhost:5000/api/v1/health
echo ============================================
echo.
echo Press Ctrl+C to stop the server.
echo.

cd /d "D:\herdoor-"
npm run dev
