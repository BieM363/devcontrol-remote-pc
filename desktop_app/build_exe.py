import sys
import os
import subprocess

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
    cloudflared_exe = os.path.join(project_root, "desktop_daemon", "cloudflared.exe")

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
        "--collect-all=customtkinter",
        f"--add-data={cloudflared_exe};desktop_daemon",
        f"--distpath={output_dir}",
        f"--paths={os.path.join(project_root, 'desktop_daemon')}",
        gui_script
    ]

    print(f"Executing: {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=project_root)

    if result.returncode == 0:
        exe_path = os.path.join(output_dir, 'DevControl-Desktop', 'DevControl-Desktop.exe')
        print("\n==================================================")
        print("SUCCESS! Executable created successfully at:")
        print(f"Path: {exe_path}")
        print("==================================================")
    else:
        print("\nBuild failed with return code:", result.returncode)

if __name__ == "__main__":
    build_exe()
