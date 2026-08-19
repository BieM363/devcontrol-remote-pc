# 📱 DevControl Flutter Mobile Client

Native Android Flutter application for controlling and coding on your PC/Laptop from your smartphone (Optimized for **ZTE Blade V50 Design** with 6.6" 1080x2408 90Hz Display).

---

## 🚀 Features

- **Hardware-Accelerated Screen Stream**: Renders low-latency PC screen stream using `Image.memory` with zero frame tearing.
- **Custom Developer Keypad**: Touch bar with IDE key bindings (`Ctrl`, `Alt`, `Shift`, `Tab`, `Esc`, `Save Ctrl+S`, `Run F5`, `Terminal Ctrl+\``), code symbols (`{`, `}`, `[`, `]`, `=>`, `;`), and navigation keys.
- **Virtual Touchpad**: Touch surface supporting single-finger cursor tracking, single tap (left click), two-finger tap (right click), and scrolling.
- **Native Soft Keyboard Integration**: Trigger Android soft keyboard for code input.
- **PIN Authentication**: 6-digit handshake security protection.

---

## 🛠 Building the APK

### Prerequisites
1. [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.0.0)
2. Android Studio / Android SDK

### Steps to Build APK

```bash
# Navigate to flutter project
cd mobile_client_flutter

# Fetch packages
flutter pub get

# Build Release APK
flutter build apk --release
```

The compiled APK will be located at:
`mobile_client_flutter/build/app/outputs/flutter-apk/app-release.apk`

Transfer and install `app-release.apk` on your **ZTE Blade V50 Design** device!
