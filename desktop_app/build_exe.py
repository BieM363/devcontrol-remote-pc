"""
DevControl - Windows Desktop Executable Builder
Author: BieM363 (https://github.com/BieM363)
Repository: https://github.com/BieM363/devcontrol-remote-pc
"""

import sys
import os
import shutil
import subprocess
import customtkinter

# Ensure UTF-8 output encoding for console print statements
sys.stdout.reconfigure(encoding='utf-8')

def build_exe():
    print("==================================================")
    print("Building DevControl Standalone PC Executable (.exe)")
    print("==================================================")

    current_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(current_dir, ".."))
    gui_script = os.path.join(current_dir, "gui.py")
    output_dir = os.path.join(project_root, "dist_desktop")
    dist_pc_dir = os.path.join(project_root, "dist_pc")
    cloudflared_exe = os.path.join(project_root, "desktop_daemon", "cloudflared.exe")
    static_dir = os.path.join(project_root, "desktop_daemon", "static")
    ctk_dir = os.path.dirname(customtkinter.__file__)

    # Terminate any old running processes to prevent file lock
    try:
        subprocess.run(["taskkill", "/F", "/IM", "DevControl-Desktop.exe"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["taskkill", "/F", "/IM", "cloudflared.exe"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    cmd = [
        sys.executable,
        "-m",
        "PyInstaller",
        "--noconfirm",
        "--onedir",
        "--windowed",
        "--name=DevControl-Desktop",
        f"--add-data={ctk_dir};customtkinter",
        f"--add-data={static_dir};desktop_daemon/static",
        f"--add-data={cloudflared_exe};desktop_daemon",
        f"--distpath={output_dir}",
        f"--paths={os.path.join(project_root, 'desktop_daemon')}",
        gui_script
    ]

    print(f"Executing PyInstaller with CustomTkinter at: {ctk_dir}")
    result = subprocess.run(cmd, cwd=project_root)

    if result.returncode == 0:
        exe_src = os.path.join(output_dir, 'DevControl-Desktop')
        exe_path = os.path.join(exe_src, 'DevControl-Desktop.exe')

        # Synchronize to dist_pc as well so both folders work flawlessly
        try:
            exe_dest = os.path.join(dist_pc_dir, 'DevControl-Desktop')
            if os.path.exists(exe_dest):
                shutil.rmtree(exe_dest)
            shutil.copytree(exe_src, exe_dest)
            print(f"Synchronized build to: {exe_dest}")
        except Exception as e:
            print(f"Sync to dist_pc notice: {e}")

        print("\n==================================================")
        print("SUCCESS! Executable created successfully at:")
        print(f"Path 1: {exe_path}")
        print(f"Path 2: {os.path.join(dist_pc_dir, 'DevControl-Desktop', 'DevControl-Desktop.exe')}")
        print("==================================================")
    else:
        print("\nBuild failed with return code:", result.returncode)

if __name__ == "__main__":
    build_exe()

