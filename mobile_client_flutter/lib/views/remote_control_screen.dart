import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/devcontrol_service.dart';
import '../widgets/screen_viewer.dart';
import '../widgets/virtual_touchpad.dart';
import '../widgets/developer_keypad.dart';

enum ScreenQualityMode { eco480p, hd720p, fhd1080p }

class RemoteControlScreen extends StatefulWidget {
  final DevControlService service;

  const RemoteControlScreen({super.key, required this.service});

  @override
  State<RemoteControlScreen> createState() => _RemoteControlScreenState();
}

class _RemoteControlScreenState extends State<RemoteControlScreen> {
  final _focusNode = FocusNode();
  final _textController = TextEditingController();
  String _lastText = "";
  int _pingMs = 0;
  
  bool _isKeyboardActive = false;
  bool _showDevKeypad = true;
  bool _showHeader = false; // Default false for 100% immersive full screen
  bool _isFloatingMenuExpanded = false; // Collapsed by default so it does NOT block the screen!
  bool _isZoomMode = false; // v2.0: Interactive Zoom In/Out & Pan Screen Mode
  TouchpadMode _touchMode = TouchpadMode.directTouch;
  
  final TransformationController _transformationController = TransformationController();
  ScreenQualityMode _qualityMode = ScreenQualityMode.hd720p;
  
  // Draggable floating button position
  final Offset _fabPosition = const Offset(16, 16); // Top-right offset relative to right edge

  @override
  void initState() {
    super.initState();
    // Enable Full Screen Immersive Sticky mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isKeyboardActive = _focusNode.hasFocus;
        });
      }
    });

    widget.service.pongStream.listen((ping) {
      if (mounted) {
        setState(() {
          _pingMs = ping;
        });
      }
    });

    // Set initial HD 720p quality on PC
    _applyQuality(ScreenQualityMode.hd720p, showToast: false);
  }

  void _applyQuality(ScreenQualityMode mode, {bool showToast = true}) {
    int targetWidth;
    int quality;
    String label;

    switch (mode) {
      case ScreenQualityMode.fhd1080p:
        targetWidth = 1920;
        quality = 85;
        label = "Full HD 1080p (Ultra Tajam)";
        break;
      case ScreenQualityMode.hd720p:
        targetWidth = 1280;
        quality = 80;
        label = "HD 720p (Tajam & Cepat)";
        break;
      case ScreenQualityMode.eco480p:
        targetWidth = 854;
        quality = 65;
        label = "Eco 480p (Hemat Data)";
        break;
    }

    setState(() {
      _qualityMode = mode;
    });

    widget.service.sendSettings(targetWidth: targetWidth, quality: quality);

    if (showToast && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.hd_rounded, color: Color(0xFF00F0FF), size: 20),
              const SizedBox(width: 8),
              Text("Kualitas Layar: $label"),
            ],
          ),
          backgroundColor: const Color(0xFF161B22),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Restore normal system UI mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _focusNode.dispose();
    _textController.dispose();
    _transformationController.dispose();
    widget.service.dispose();
    super.dispose();
  }

  void _onTextChanged(String currentText) {
    if (currentText.length > _lastText.length) {
      // New character(s) typed
      if (currentText.startsWith(_lastText)) {
        final diff = currentText.substring(_lastText.length);
        widget.service.sendTypeText(diff);
      } else {
        // Replacement / autocomplete
        final diff = currentText.substring(currentText.length - 1);
        widget.service.sendTypeText(diff);
      }
    } else if (currentText.length < _lastText.length) {
      // Backspace pressed
      final deleteCount = _lastText.length - currentText.length;
      for (int i = 0; i < deleteCount; i++) {
        widget.service.sendKeyPress('backspace');
      }
    }
    _lastText = currentText;

    // Reset buffer every 20 characters to prevent buffer buildup
    if (_lastText.length > 20) {
      _lastText = "";
      _textController.value = TextEditingValue.empty;
    }
  }

  void _toggleNativeKeyboard() {
    HapticFeedback.mediumImpact();
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white12),
          ),
          title: const Row(
            children: [
              Icon(Icons.high_quality_rounded, color: Color(0xFF00F0FF)),
              SizedBox(width: 8),
              Text("Resolusi & Kualitas Layar", style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQualityOption(
                title: "HD 720p (Rekomendasi)",
                subtitle: "Teks tajam, jernih & responsif (1280x720)",
                mode: ScreenQualityMode.hd720p,
              ),
              const Divider(color: Colors.white10),
              _buildQualityOption(
                title: "Full HD 1080p (Ultra Tajam)",
                subtitle: "Kerapatan piksel penuh monitor (1920x1080)",
                mode: ScreenQualityMode.fhd1080p,
              ),
              const Divider(color: Colors.white10),
              _buildQualityOption(
                title: "Eco 480p (Hemat Kuota)",
                subtitle: "Kompresi tinggi untuk sinyal lemah (854x480)",
                mode: ScreenQualityMode.eco480p,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup", style: TextStyle(color: Color(0xFF00F0FF))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQualityOption({
    required String title,
    required String subtitle,
    required ScreenQualityMode mode,
  }) {
    final isSelected = _qualityMode == mode;
    return InkWell(
      onTap: () {
        _applyQuality(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF00F0FF) : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF00F0FF) : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickTextDialog() {
    final directController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.send_rounded, color: Color(0xFF00F0FF), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Kirim Teks / Perintah Langsung ke PC",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: directController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontFamily: 'Fira Code', fontSize: 14),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Ketik kode, URL, atau perintah terminal di sini...",
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00F0FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text("KIRIM KE PC", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        final text = directController.text;
                        if (text.isNotEmpty) {
                          widget.service.sendTypeText(text);
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.keyboard_return, size: 18),
                    label: const Text("Enter"),
                    onPressed: () {
                      final text = directController.text;
                      if (text.isNotEmpty) {
                        widget.service.sendTypeText(text);
                      }
                      widget.service.sendKeyPress('enter');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // Prevents viewport squashing when soft keyboard opens
      body: Column(
        children: [
          // OPTIONAL TOP METRICS BAR (Hidden by default for maximum screen)
          if (_showHeader)
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              color: const Color(0xFF0D1117),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 9, color: Color(0xFF2ECC71)),
                  const SizedBox(width: 6),
                  const Text("DevControl Connected", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "BieM363",
                      style: TextStyle(color: Color(0xFF00F0FF), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Ping: ${_pingMs}ms",
                      style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontFamily: 'Fira Code'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      widget.service.disconnect();
                      Navigator.of(context).pushReplacementNamed('/');
                    },
                  ),
                ],
              ),
            ),

          // FULLSCREEN SCREEN VIEWPORT & TOUCHPAD OVERLAY
          Expanded(
            child: Stack(
              children: [
                // SCREEN STREAM WITH INTERACTIVE ZOOM & PAN (v2.0)
                InteractiveViewer(
                  transformationController: _transformationController,
                  panEnabled: _isZoomMode,
                  scaleEnabled: _isZoomMode,
                  minScale: 1.0,
                  maxScale: 6.0,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox.expand(
                    child: ScreenViewer(service: widget.service),
                  ),
                ),

                // VIRTUAL TOUCHPAD GESTURES (Active in Cursor Mode)
                if (!_isZoomMode)
                  Positioned.fill(
                    child: VirtualTouchpad(
                      service: widget.service,
                      mode: _touchMode,
                      transformationController: _transformationController,
                    ),
                  ),

                // FLOATING ZOOM MODE ACTIVE BANNER (v2.0)
                if (_isZoomMode)
                  Positioned(
                    top: 16,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117).withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFB800), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_in_rounded, color: Color(0xFFFFB800), size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "Mode Zoom & Geser Layar",
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _transformationController.value = Matrix4.identity();
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "Reset 1.0x",
                                  style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // HIDDEN TEXT FIELD FOR NATIVE SOFT KEYBOARD WITH DELTA ENGINE
                Positioned(
                  top: -200,
                  left: -200,
                  child: SizedBox(
                    width: 10,
                    height: 10,
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.send,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: _onTextChanged,
                      onSubmitted: (value) {
                        widget.service.sendKeyPress('enter');
                        _lastText = "";
                        _textController.clear();
                        _focusNode.requestFocus();
                      },
                    ),
                  ),
                ),

                // SLEEK COLLAPSIBLE & DRAGGABLE FLOATING TOOLBAR
                Positioned(
                  right: _fabPosition.dx,
                  top: _fabPosition.dy,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117).withValues(alpha: _isFloatingMenuExpanded ? 0.92 : 0.65),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isFloatingMenuExpanded ? const Color(0xFF00F0FF).withValues(alpha: 0.5) : Colors.white24,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isFloatingMenuExpanded
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. KEYBOARD TOGGLE BUTTON (Glowing Active State)
                              _buildFloatingIconBtn(
                                icon: Icons.keyboard_rounded,
                                tooltip: "Buka / Tutup Keyboard HP",
                                isActive: _isKeyboardActive,
                                activeColor: const Color(0xFF00F0FF),
                                onTap: _toggleNativeKeyboard,
                              ),
                              const SizedBox(width: 4),

                              // 2. DEV KEYPAD TOGGLE
                              _buildFloatingIconBtn(
                                icon: Icons.terminal_rounded,
                                tooltip: "Toggle Toolbar Tombol Coding",
                                isActive: _showDevKeypad,
                                activeColor: const Color(0xFFD1A3FF),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _showDevKeypad = !_showDevKeypad;
                                  });
                                },
                              ),
                              const SizedBox(width: 4),

                              // 3. HD QUALITY SELECTOR
                              _buildFloatingIconBtn(
                                icon: Icons.hd_rounded,
                                tooltip: "Kualitas Layar HD (720p/1080p)",
                                isActive: _qualityMode != ScreenQualityMode.eco480p,
                                activeColor: const Color(0xFF00F0FF),
                                onTap: _showQualityDialog,
                              ),
                              const SizedBox(width: 4),

                              // 4. DIRECT TEXT SENDER MODAL
                              _buildFloatingIconBtn(
                                icon: Icons.chat_bubble_outline_rounded,
                                tooltip: "Kirim Teks Panjang / Script",
                                isActive: false,
                                onTap: _showQuickTextDialog,
                              ),
                              const SizedBox(width: 4),

                              // 5. ZOOM & PAN MODE TOGGLE (v2.0: Perbesar, Perkecil & Geser Layar)
                              _buildFloatingIconBtn(
                                icon: Icons.zoom_in_rounded,
                                tooltip: _isZoomMode ? "Kembali ke Mode Kursor" : "Mode Zoom & Geser Layar",
                                isActive: _isZoomMode,
                                activeColor: const Color(0xFFFFB800),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _isZoomMode = !_isZoomMode;
                                  });
                                },
                              ),
                              const SizedBox(width: 4),

                              // 6. TOUCH MODE TOGGLE (Direct Touch vs Virtual Trackpad)
                              _buildFloatingIconBtn(
                                icon: _touchMode == TouchpadMode.directTouch ? Icons.touch_app_rounded : Icons.mouse_rounded,
                                tooltip: _touchMode == TouchpadMode.directTouch ? "Mode Sentuh Langsung (Tap Layar)" : "Mode Trackpad Mouse (Geser Kursor)",
                                isActive: _touchMode == TouchpadMode.relativeTrackpad,
                                activeColor: const Color(0xFFFFCC00),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _touchMode = _touchMode == TouchpadMode.directTouch
                                        ? TouchpadMode.relativeTrackpad
                                        : TouchpadMode.directTouch;
                                  });
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(
                                            _touchMode == TouchpadMode.directTouch ? Icons.touch_app_rounded : Icons.mouse_rounded,
                                            color: const Color(0xFF00F0FF),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _touchMode == TouchpadMode.directTouch
                                                ? "Mode Sentuh Langsung: Tap layar PC"
                                                : "Mode Trackpad Mouse: Geser kursor seperti touchpad laptop",
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF161B22),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),

                              // 7. FULLSCREEN / HEADER TOGGLE
                              _buildFloatingIconBtn(
                                icon: _showHeader ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                                tooltip: "Toggle Layar Penuh",
                                isActive: _showHeader,
                                activeColor: const Color(0xFF2ECC71),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _showHeader = !_showHeader;
                                  });
                                },
                              ),
                              const SizedBox(width: 4),

                              // 8. COLLAPSE / MINIMIZE BUTTON (Menutup Menu Agar Tidak Menghalangi Layar)
                              InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _isFloatingMenuExpanded = false;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        : InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _isFloatingMenuExpanded = true;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isKeyboardActive ? Icons.keyboard_rounded : Icons.tune_rounded,
                                    size: 18,
                                    color: _isKeyboardActive ? const Color(0xFF00F0FF) : Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "Menu",
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // DEVELOPER CODING KEYPAD (Collapsible)
          if (_showDevKeypad)
            DeveloperKeypad(
              service: widget.service,
              onToggleNativeKeyboard: _toggleNativeKeyboard,
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingIconBtn({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = isActive ? (activeColor ?? const Color(0xFF00F0FF)) : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? (activeColor ?? const Color(0xFF00F0FF)).withValues(alpha: 0.2) : Colors.transparent,
            shape: BoxShape.circle,
            border: isActive ? Border.all(color: (activeColor ?? const Color(0xFF00F0FF)), width: 1.5) : null,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
