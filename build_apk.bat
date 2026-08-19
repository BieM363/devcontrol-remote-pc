@echo off
title DevControl - Build Android APK
echo ==================================================
echo DevControl Native Android APK Builder
echo Target Device: ZTE Blade V50 Design
echo ==================================================
echo.

:: Detect Java 17 location if available
for /d %%d in ("C:\Program Files\Microsoft\JDK-17*") do set "JAVA_HOME=%%d"
for /d %%d in ("C:\Program Files\Java\jdk-17*") do set "JAVA_HOME=%%d"

if defined JAVA_HOME (
    set "PATH=%JAVA_HOME%\bin;%PATH%"
)

if exist "C:\android-sdk" (
    set "ANDROID_HOME=C:\android-sdk"
    set "ANDROID_SDK_ROOT=C:\android-sdk"
    set "PATH=C:\android-sdk\cmdline-tools\latest\bin;C:\android-sdk\platform-tools;%PATH%"
)

set "FLUTTER_CMD=flutter"

where flutter >nul 2>nul
if errorlevel 1 (
    if exist "C:\flutter\bin\flutter.bat" (
        set "FLUTTER_CMD=C:\flutter\bin\flutter.bat"
    ) else (
        echo [!] ERROR: Flutter SDK belum ter-install di C:\flutter
        echo.
        echo Silakan jalankan file: install_flutter.bat terlebih dahulu!
        pause
        exit /b 1
    )
)

echo [v] Flutter SDK ^& Android SDK terdeteksi! Memulai kompilasi file APK...
cd mobile_client_flutter
call %FLUTTER_CMD% pub get
call %FLUTTER_CMD% build apk --release

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo.
    echo ==================================================
    echo [v] BERHASIL! File APK telah dibuat di:
    echo mobile_client_flutter\build\app\outputs\flutter-apk\app-release.apk
    echo ==================================================
) else (
    echo.
    echo [!] Gagal membuat file APK. Periksa log kesalahan di atas.
)

echo.
pause
