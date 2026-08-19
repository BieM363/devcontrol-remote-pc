import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/devcontrol_service.dart';
import 'remote_control_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _urlController = TextEditingController(text: "wss://");
  final _pinController = TextEditingController();
  final _service = DevControlService();
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _authSubscription;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString("last_ws_url");
      final savedPin = prefs.getString("last_pin");
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _urlController.text = savedUrl;
      }
      if (savedPin != null && savedPin.isNotEmpty) {
        _pinController.text = savedPin;
      }
    } catch (_) {}
  }

  void _saveCredentials(String url, String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("last_ws_url", url);
      await prefs.setString("last_pin", pin);
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _handleConnect() async {
    String rawUrl = _urlController.text.trim();
    final pin = _pinController.text.trim();

    if (rawUrl.isEmpty) {
      setState(() {
        _errorMessage = "Masukkan WebSocket URL / Cloudflare Tunnel";
      });
      return;
    }

    if (pin.length != 6) {
      setState(() {
        _errorMessage = "PIN harus 6 digit angka dari laptop";
      });
      return;
    }

    // Clean raw URL (remove angle brackets, quotes, whitespace, https/http prefix)
    rawUrl = rawUrl.replaceAll("<", "").replaceAll(">", "").replaceAll('"', '').trim();
    if (rawUrl.startsWith("https://")) {
      rawUrl = rawUrl.replaceFirst("https://", "wss://");
    } else if (rawUrl.startsWith("http://")) {
      rawUrl = rawUrl.replaceFirst("http://", "ws://");
    } else if (!rawUrl.startsWith("ws://") && !rawUrl.startsWith("wss://")) {
      if (rawUrl.contains("trycloudflare") || rawUrl.contains("ngrok")) {
        rawUrl = "wss://$rawUrl";
      } else {
        rawUrl = "ws://$rawUrl";
      }
    }
    _urlController.text = rawUrl;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _authSubscription?.cancel();
    _timeoutTimer?.cancel();

    // 8 Seconds Connection Timeout Safety
    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Koneksi RTO (Timeout)! Periksa URL / Tunnel.";
        });
        _service.disconnect();
      }
    });

    try {
      await _service.connect(rawUrl, pin);

      _authSubscription = _service.authStream.listen((authResult) {
        _timeoutTimer?.cancel();
        if (mounted) {
          if (authResult['success'] == true) {
            _saveCredentials(rawUrl, pin);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => RemoteControlScreen(service: _service),
              ),
            );
          } else {
            setState(() {
              _isLoading = false;
              _errorMessage = authResult['message'] ?? "PIN Keamanan Salah!";
            });
            _service.disconnect();
          }
        }
      });
    } catch (e) {
      _timeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Gagal terhubung! Pastikan URL memiliki wss://";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("📱💻", style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  const Text(
                    "DevControl",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00F0FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      "ZTE Blade V50 Native Client",
                      style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // URL INPUT
                  TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Daemon WebSocket / Cloudflare URL",
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.wifi_rounded, color: Color(0xFF00F0FF)),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PIN INPUT
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 28,
                      letterSpacing: 8,
                      fontFamily: 'Fira Code',
                    ),
                    decoration: InputDecoration(
                      hintText: "••••••",
                      hintStyle: const TextStyle(color: Colors.white24),
                      counterText: "",
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00F0FF),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _handleConnect,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                            )
                          : const Text(
                              "Connect & Start Coding",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "DevControl v1.2 • Crafted with ❤️ by BieM363",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


