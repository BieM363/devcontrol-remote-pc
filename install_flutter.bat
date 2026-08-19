@echo off
title DevControl - Automated Flutter SDK Installer
echo ==================================================
echo Automated Flutter SDK Installer for Windows
echo ==================================================
echo.

if exist "C:\flutter\bin\flutter.bat" (
    echo [✓] Flutter SDK sudah terpasang di C:\flutter
    goto ADD_PATH
)

echo [1/3] Mengunduh Flutter SDK dari repository resmi (Git)...
git clone -b stable https://github.com/flutter/flutter.git C:\flutter

if not exist "C:\flutter\bin\flutter.bat" (
    echo [!] Gagal mengunduh Flutter SDK. Pastikan koneksi internet lancar.
    pause
    exit /b 1
)

:ADD_PATH
echo [2/3] Menambahkan C:\flutter\bin ke PATH Windows...
setx PATH "%PATH%;C:\flutter\bin" /M 2>nul || setx PATH "%PATH%;C:\flutter\bin"

set "PATH=%PATH%;C:\flutter\bin"

echo [3/3] Memasang Dart SDK dan mengkonfirmasi Flutter...
call C:\flutter\bin\flutter.bat doctor

echo.
echo ==================================================
echo [✓] SUKSES! Flutter SDK telah terpasang di C:\flutter
echo Sekarang kamu bisa menjalankan file build_apk.bat!
echo ==================================================
echo.
pause
