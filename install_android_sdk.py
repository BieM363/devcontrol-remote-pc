import os
import sys
import glob
import zipfile
import urllib.request
import subprocess

sys.stdout.reconfigure(encoding='utf-8')

SDK_DIR = r"C:\android-sdk"
CMDLINE_URL = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
ZIP_PATH = os.path.join(SDK_DIR, "cmdline-tools.zip")

def find_jdk17():
    possible_paths = [
        r"C:\Program Files\Microsoft\JDK-17*",
        r"C:\Program Files\Java\jdk-17*",
        r"C:\Program Files\Eclipse Adoptium\jdk-17*"
    ]
    for pattern in possible_paths:
        matches = glob.glob(pattern)
        if matches:
            return matches[0]
    return None

def install_android_sdk():
    print("==================================================")
    print("🚀 Configuring Android SDK & Java 17 environment...")
    print("==================================================")

    jdk_path = find_jdk17()
    if jdk_path:
        print(f"[✓] JDK 17 detected at: {jdk_path}")
        os.environ["JAVA_HOME"] = jdk_path
        os.environ["PATH"] = f"{os.path.join(jdk_path, 'bin')};{os.environ['PATH']}"
        subprocess.run(f'setx JAVA_HOME "{jdk_path}" /M 2>nul || setx JAVA_HOME "{jdk_path}"', shell=True)

    os.makedirs(SDK_DIR, exist_ok=True)
    latest_dir = os.path.join(SDK_DIR, "cmdline-tools", "latest")
    sdkmanager_bin = os.path.join(latest_dir, "bin", "sdkmanager.bat")

    if not os.path.exists(sdkmanager_bin):
        print(f"[1/4] Downloading Android Command-Line Tools from Google...")
        curl_cmd = f'curl -L -o "{ZIP_PATH}" "{CMDLINE_URL}"'
        res = subprocess.run(curl_cmd, shell=True)

        print(f"[✓] Extracting archive to C:\\android-sdk...")
        temp_extract = os.path.join(SDK_DIR, "temp_cmdline")
        with zipfile.ZipFile(ZIP_PATH, 'r') as zip_ref:
            zip_ref.extractall(temp_extract)

        os.makedirs(latest_dir, exist_ok=True)
        extracted_cmdline = os.path.join(temp_extract, "cmdline-tools")
        subprocess.run(f'xcopy "{extracted_cmdline}\*" "{latest_dir}" /E /I /Y', shell=True, stdout=subprocess.DEVNULL)
        
        if os.path.exists(ZIP_PATH):
            os.remove(ZIP_PATH)

    print(f"[2/4] Setting ANDROID_HOME environment variables...")
    os.environ["ANDROID_HOME"] = SDK_DIR
    os.environ["ANDROID_SDK_ROOT"] = SDK_DIR
    cmdline_bin = os.path.join(latest_dir, "bin")
    platform_tools_bin = os.path.join(SDK_DIR, "platform-tools")
    os.environ["PATH"] = f"{cmdline_bin};{platform_tools_bin};{os.environ['PATH']}"
    
    subprocess.run(f'setx ANDROID_HOME "{SDK_DIR}" /M 2>nul || setx ANDROID_HOME "{SDK_DIR}"', shell=True)

    print(f"[3/4] Auto-accepting Android SDK Licenses...")
    licenses_dir = os.path.join(SDK_DIR, "licenses")
    os.makedirs(licenses_dir, exist_ok=True)
    
    license_files = {
        "android-sdk-license": "24333f8a63718c1e5b59c25b6024c6e1ede5365a\n8933b2222019320a81c0003a386c14a0782c1acd\nd56f51854706324973b85720a7612788779474b6",
        "android-sdk-preview-license": "84831b9409646a918e30573bab4c9c91346d8abd",
        "intel-android-sysimage-license": "d975f751698a7706658025a3cc832a136fa755fe"
    }
    for l_name, l_content in license_files.items():
        with open(os.path.join(licenses_dir, l_name), "w") as f:
            f.write(l_content)

    print(f"[4/4] Installing platform-tools & build-tools via sdkmanager...")
    pkgs = ["platform-tools", "build-tools;34.0.0", "platforms;android-34"]
    for pkg in pkgs:
        print(f"Installing {pkg}...")
        cmd = f'"{sdkmanager_bin}" --sdk_root="{SDK_DIR}" "{pkg}"'
        p = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, text=True)
        p.communicate(input="y\ny\ny\ny\ny\n")

    print("\n==================================================")
    print("✅ SUCCESS! Android SDK & JDK 17 configured at C:\\android-sdk")
    print("==================================================")

if __name__ == "__main__":
    install_android_sdk()
