# 📱💻 DevControl: Cross-Network Native Remote PC Controller for Mobile Coding

<div align="center">

![Author](https://img.shields.io/badge/Author-BieM363-00f0ff?style=for-the-badge&logo=github)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Target](https://img.shields.io/badge/Target-ZTE%20Blade%20V50%20Design-purple?style=for-the-badge)
![Engine](https://img.shields.io/badge/Engine-Windows%20GDI%20Hardware%20Capture%20(50%2B%20FPS)-orange?style=for-the-badge)

**Crafted with ❤️ by [BieM363](https://github.com/BieM363/devcontrol-remote-pc)**

</div>

---

## 🌟 Overview

**DevControl** is a high-performance native desktop server and mobile client suite allowing developers to control, code, and interact with their PC / Laptop directly from their smartphone—over local Wi-Fi or cellular 4G/5G mobile data anywhere without complex router port-forwarding.

---

## 🚀 Key Features

1. **Ultra-Low Latency Screen Streaming (50+ FPS)**:
   - Powered by native **Windows GDI Direct Hardware Capture** (`user32.dll` + `gdi32.dll` `BitBlt` with `0x00CC0020`).
   - Frame capture in **< 19ms** with zero memory leaks.
   - Dynamic JPEG subsampling (~15–25 KB per frame) perfectly optimized for Telkomsel 4G cellular networks without lag buildup.
   - Zero-backpressure frame skipping over WebSockets to prevent frame queuing.

2. **Text Selection & Clipboard Toolbar**:
   - 🔲 **Block All / Select All** (`Ctrl+A`)
   - 📋 **Copy** (`Ctrl+C`)
   - 📥 **Paste** (`Ctrl+V`)
   - ✂️ **Cut** (`Ctrl+X`)
   - 🔍 **Selection Navigation** (`Shift+←`, `Shift+→`, `Shift+↑`, `Shift+↓`)
   - ⚡ **Interactive Shift/Ctrl/Alt Modifier Toggles**: Tap Shift to activate text block selection mode with normal arrow keys!

3. **Seamless Cloudflare Zero-Config Tunneling**:
   - Built-in `cloudflared` integration creates a secure public `wss://*.trycloudflare.com` tunnel in seconds.
   - 1-click clipboard URL copying on PC and 1-tap **📋 Tempel (Paste)** button on mobile.
   - Auto-cleans and sanitizes URLs to avoid cut-off links or trailing slash mismatches.

4. **Developer Keypad & Symbols**:
   - Fast touch keys for IDE shortcuts (`Ctrl`, `Alt`, `Shift`, `Tab`, `Esc`, `Save`, `Run F5`, `Terminal`).
   - Code symbols (`{`, `}`, `[`, `]`, `(`, `)`, `;`, `=>`, `|`, `"`, `'`).
   - Arrow keys, Backspace, Delete, Undo (`Ctrl+Z`), and Enter.

5. **Virtual Touchpad & Multi-touch Gestures**:
   - High-precision cursor tracking with 0ms `pyautogui` input execution.
   - Single-tap left click, two-finger right click, two-finger code editor scrolling, and pinch zooming.

6. **Dual Client Flexibility**:
   - **Instant Web PWA**: Zero installation needed—open in Chrome/Edge on smartphone.
   - **Native Android App (Flutter)**: 90Hz smooth rendering, hardware haptics, and immersive fullscreen mode.

7. **Session PIN Handshake**:
   - 6-digit session PIN authentication with rate-limiting security lockout against brute-force attempts.

---

## 📁 Project Architecture

```text
├── desktop_daemon/                 # Python Desktop Server (PC / Laptop)
│   ├── main.py                     # CLI entry point with UTF-8 encoding configuration
│   ├── web_server.py               # WebSocket & HTTP real-time server with backpressure protection
│   ├── screencap.py                # High-speed Windows GDI BitBlt screen capture & compression engine
│   ├── input_handler.py            # Zero-delay mouse/keyboard automation (pynput + pyautogui)
│   ├── auth.py                     # 6-digit session PIN & token manager with lockout protection
│   ├── tunnel_manager.py           # Cloudflare & Ngrok remote tunnel manager (IPv4 target)
│   ├── requirements.txt            # Python dependencies
│   └── static/                     # Mobile Web PWA Client (Instant mobile access)
│       ├── index.html
│       ├── style.css
│       └── app.js
│
├── desktop_app/                    # Desktop GUI Server (CustomTkinter)
│   ├── gui.py                      # Modern Dark Mode GUI Desktop Control Panel
│   └── build_exe.py                # PyInstaller standalone executable builder with bundled themes
│
├── mobile_client_flutter/          # Native Android Flutter Codebase
│   ├── lib/                        # Views, widgets, and WebSocket services
│   │   ├── views/                  # Connect screen & Remote control screen
│   │   ├── widgets/                # Developer keypad, screen viewer & virtual touchpad
│   │   └── services/               # DevControl WebSocket service with binary stream parser
│   └── pubspec.yaml                # Flutter project configuration
│
├── dist_pc/                        # Compiled Windows Standalone Executable
├── dist_desktop/                   # Compiled Windows Standalone Executable
├── DevControl-Mobile-v1.2.apk      # Compiled Android Release APK
├── build_exe.bat                   # 1-Click Desktop Executable Compiler
├── build_apk.bat                   # 1-Click Android Release APK Compiler
└── README.md
```

---

## 🛠️ Quick Start Guide

### 1. Launch Server (PC / Laptop)

#### Option A: Standalone Executable (.exe)
Double click `DevControl-Desktop.exe` inside `dist_pc/DevControl-Desktop/` and click **🚀 START DAEMON SERVER**.

#### Option B: From Source Code
```bash
# Install dependencies
pip install -r desktop_daemon/requirements.txt

# Run Desktop GUI
python desktop_app/gui.py

# Or run CLI daemon
python desktop_daemon/main.py
```

### 2. Connect from Smartphone

1. **Cloudflare Remote Tunnel**:
   - Copy the Cloudflare URL from the desktop panel (e.g. `wss://*.trycloudflare.com`).
   - On the smartphone, open the **DevControl Android App** (or Chrome browser).
   - Tap the **📋 Tempel** button to paste the URL.
   - Enter the **6-digit PIN** displayed on your laptop.
   - Tap **Connect & Start Coding**!

---

## 👤 Author & Credits

- **Creator & Lead Developer**: **BieM363**
- **Repository**: [https://github.com/BieM363/devcontrol-remote-pc](https://github.com/BieM363/devcontrol-remote-pc)
- **License**: MIT License


