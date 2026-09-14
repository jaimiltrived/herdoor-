@echo off
title HerDoor - Stop All Services
color 0C

echo ============================================
echo    Stopping HerDoor Services
echo ============================================
echo.

echo [1/3] Stopping Node.js...
taskkill /F /IM node.exe 2>NUL
echo       Done.

echo [2/3] Stopping MySQL...
"C:\xampp\mysql\bin\mysqladmin.exe" -u root -P 3307 -h 127.0.0.1 shutdown 2>NUL
timeout /t 2 /nobreak >NUL
taskkill /F /IM mysqld.exe 2>NUL
echo       Done.

echo [3/3] Stopping Apache...
taskkill /F /IM httpd.exe 2>NUL
echo       Done.

echo.
echo All services stopped.
pause
