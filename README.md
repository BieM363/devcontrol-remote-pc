# 📱💻 DevControl: Cross-Network Native Remote PC Controller for Mobile Coding

<div align="center">

![Author](https://img.shields.io/badge/Author-BieM363-00f0ff?style=for-the-badge&logo=github)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Target](https://img.shields.io/badge/Target-ZTE%20Blade%20V50%20Design-purple?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Ultra%20Low%20Latency-orange?style=for-the-badge)

**Crafted with ❤️ by [BieM363](https://github.com/BieM363/devcontrol-remote-pc)**

</div>

---

## 🌟 Overview

**DevControl** is a high-performance native desktop daemon and mobile client suite allowing developers to control, code, and interact with their PC / Laptop directly from their smartphone—over local Wi-Fi or cellular 4G/5G mobile data anywhere.

---

## 🚀 Key Features

1. **Ultra-Low Latency Screen Streaming**: Direct MSS hardware screen grabber, multi-threaded JPEG/WebP compression, and zero-backpressure WebSocket frame pipelines.
2. **Text Selection & Clipboard Toolbar**:
   - 🔲 **Block All / Select All** (`Ctrl+A`)
   - 📋 **Copy** (`Ctrl+C`)
   - 📥 **Paste** (`Ctrl+V`)
   - ✂️ **Cut** (`Ctrl+X`)
   - 🔍 **Selection Navigation** (`Shift+←`, `Shift+→`, `Shift+↑`, `Shift+↓`)
   - ⚡ **Interactive Shift/Ctrl/Alt Modifier Toggles**: Tap Shift to activate text block selection mode with normal arrow keys!
3. **Cross-Network Cellular 4G/5G Access**: Built-in Cloudflare Zero-Config Tunneling and Ngrok support for coding on the go without port forwarding.
4. **Developer Keypad & Symbols**: Fast touch keys for IDE shortcuts (`Ctrl`, `Alt`, `Shift`, `Tab`, `Esc`, `Save`, `Run F5`, `Terminal`), code symbols (`{`, `}`, `[`, `]`, `=>`, `|`, `;`, `"`, `'`), and arrow navigation.
5. **Virtual Touchpad & Multi-touch Gestures**: High-precision cursor tracking, single-tap left click, two-finger right click, two-finger code editor scrolling, and pinch zooming.
6. **Dual Client Flexibility**:
   - **Instant Web PWA**: Zero installation needed—scan QR code in phone browser.
   - **Native Android App (Flutter)**: 90Hz smooth rendering, hardware haptics, and immersive full screen mode.
7. **Session PIN Handshake**: 6-digit session PIN authentication with rate-limiting security lockout.

---

## 📁 Project Architecture

```text
├── desktop_daemon/                 # Python Desktop Server (PC / Laptop)
│   ├── main.py                     # CLI entry point with QR code generator
│   ├── web_server.py               # WebSocket & HTTP real-time server
│   ├── screencap.py                # High-speed screen capture & compression engine
│   ├── input_handler.py            # Zero-delay mouse/keyboard automation (pynput)
│   ├── auth.py                     # 6-digit session PIN & HMAC token manager
│   ├── tunnel_manager.py           # Cloudflare & Ngrok remote tunnel manager
│   ├── requirements.txt            # Python dependencies
│   └── static/                     # Mobile Web PWA Client (Instant mobile access)
│       ├── index.html
│       ├── style.css
│       └── app.js
│
├── desktop_app/                    # Desktop GUI Server (CustomTkinter)
│   ├── gui.py                      # Modern Dark Mode GUI Desktop Control Panel
│   └── build_exe.py                # PyInstaller executable builder
│
├── mobile_client_flutter/          # Native Android Flutter Codebase
│   ├── lib/                        # Views, widgets, and WebSocket services
│   └── pubspec.yaml                # Flutter project configuration
│
└── README.md
```

---

## 🛠️ Quick Start Guide

### 1. Launch Server (PC / Laptop)

```bash
# Navigate to desktop_daemon
cd desktop_daemon

# Install requirements
pip install -r requirements.txt

# Option A: Start CLI Daemon
python main.py

# Option B: Start Desktop GUI Panel
python ../desktop_app/gui.py
```

### 2. Connect from Mobile Phone

- **Instant Web Client**: Open `http://<LAPTOP_IP>:8080` (or Cloudflare URL) in Chrome / Edge on your smartphone and enter your 6-digit PIN.
- **Native Android App**: Build and install `mobile_client_flutter` on your device.

---

## 👤 Author & Credits

- **Creator & Lead Developer**: **BieM363**
- **Repository**: [https://github.com/BieM363/devcontrol-remote-pc](https://github.com/BieM363/devcontrol-remote-pc)
- **License**: MIT License

