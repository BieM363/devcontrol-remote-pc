@echo off
title DevControl - Native PC Controller Server
echo ==================================================
echo Starting DevControl Desktop Server...
echo ==================================================

if exist "dist_desktop\DevControl-Desktop\DevControl-Desktop.exe" (
    start "" "dist_desktop\DevControl-Desktop\DevControl-Desktop.exe"
) else (
    python desktop_app\gui.py
)
