import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/devcontrol_service.dart';

class DeveloperKeypad extends StatefulWidget {
  final DevControlService service;
  final VoidCallback onToggleNativeKeyboard;

  const DeveloperKeypad({
    super.key,
    required this.service,
    required this.onToggleNativeKeyboard,
  });

  @override
  State<DeveloperKeypad> createState() => _DeveloperKeypadState();
}

class _DeveloperKeypadState extends State<DeveloperKeypad> {
  bool _isShiftActive = false;
  bool _isCtrlActive = false;
  bool _isAltActive = false;
  bool _showSelectionRow = true;

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _handleArrowPress(String direction) {
    if (_isShiftActive) {
      widget.service.sendShortcut(['shift', direction]);
    } else if (_isCtrlActive) {
      widget.service.sendShortcut(['ctrl', direction]);
    } else {
      widget.service.sendKeyPress(direction);
    }
  }

  Widget _buildKeyButton({
    required String label,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color? textColor,
    bool isActive = false,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        height: 36,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive
                ? const Color(0xFF00F0FF)
                : (backgroundColor ?? const Color(0xFF1E242E)),
            foregroundColor: isActive ? Colors.black : (textColor ?? Colors.white),
            padding: EdgeInsets.zero,
            elevation: isActive ? 4 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7.0),
              side: BorderSide(
                color: isActive
                    ? const Color(0xFF00F0FF)
                    : Colors.white.withValues(alpha: 0.12),
                width: isActive ? 1.5 : 1.0,
              ),
            ),
          ),
          onPressed: () {
            _triggerHaptic();
            onTap();
          },
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Fira Code',
              color: isActive ? Colors.black : (textColor ?? Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ROW 1: PRIMARY SHORTCUTS & SYSTEM MODIFIERS
          Row(
            children: [
              _buildKeyButton(
                label: 'Esc',
                onTap: () => widget.service.sendKeyPress('esc'),
                backgroundColor: const Color(0xFF2D3748),
              ),
              _buildKeyButton(
                label: 'Tab ⇥',
                onTap: () => widget.service.sendKeyPress('tab'),
                backgroundColor: const Color(0xFF2D3748),
              ),
              _buildKeyButton(
                label: 'Ctrl',
                onTap: () {
                  setState(() => _isCtrlActive = !_isCtrlActive);
                },
                isActive: _isCtrlActive,
                backgroundColor: const Color(0xFF4A154B),
                textColor: const Color(0xFFD1A3FF),
              ),
              _buildKeyButton(
                label: 'Alt',
                onTap: () {
                  setState(() => _isAltActive = !_isAltActive);
                },
                isActive: _isAltActive,
                backgroundColor: const Color(0xFF4A154B),
                textColor: const Color(0xFFD1A3FF),
              ),
              _buildKeyButton(
                label: 'Shift',
                onTap: () {
                  setState(() => _isShiftActive = !_isShiftActive);
                },
                isActive: _isShiftActive,
                backgroundColor: const Color(0xFF4A154B),
                textColor: const Color(0xFFD1A3FF),
              ),
              _buildKeyButton(
                label: '💾 Save',
                onTap: () => widget.service.sendShortcut(['ctrl', 's']),
                backgroundColor: const Color(0xFF003847),
                textColor: const Color(0xFF00F0FF),
              ),
              _buildKeyButton(
                label: '▶ Run',
                onTap: () => widget.service.sendShortcut(['f5']),
                backgroundColor: const Color(0xFF003847),
                textColor: const Color(0xFF00F0FF),
              ),
              _buildKeyButton(
                label: '✂️ Sel',
                onTap: () {
                  setState(() => _showSelectionRow = !_showSelectionRow);
                },
                isActive: _showSelectionRow,
                backgroundColor: const Color(0xFF1B3B2B),
                textColor: const Color(0xFF5EFFC8),
              ),
              _buildKeyButton(
                label: '⌨️',
                onTap: widget.onToggleNativeKeyboard,
                backgroundColor: const Color(0xFF004D40),
                textColor: const Color(0xFF64FFDA),
              ),
            ],
          ),
          const SizedBox(height: 3.0),

          // ROW 2: TEXT CLIPBOARD & MOUSE CONTROLS (v2.0)
          if (_showSelectionRow) ...[
            Row(
              children: [
                _buildKeyButton(
                  label: '🔲 Block All',
                  onTap: () => widget.service.sendShortcut(['ctrl', 'a']),
                  backgroundColor: const Color(0xFF0F3D3E),
                  textColor: const Color(0xFF00F0FF),
                ),
                _buildKeyButton(
                  label: '📋 Copy',
                  onTap: () => widget.service.sendShortcut(['ctrl', 'c']),
                  backgroundColor: const Color(0xFF1B3B2B),
                  textColor: const Color(0xFF5EFFC8),
                ),
                _buildKeyButton(
                  label: '📥 Paste',
                  onTap: () => widget.service.sendShortcut(['ctrl', 'v']),
                  backgroundColor: const Color(0xFF1B3B2B),
                  textColor: const Color(0xFF5EFFC8),
                ),
                _buildKeyButton(
                  label: '✂️ Cut',
                  onTap: () => widget.service.sendShortcut(['ctrl', 'x']),
                  backgroundColor: const Color(0xFF4A1E2B),
                  textColor: const Color(0xFFFF7675),
                ),
                _buildKeyButton(
                  label: '🖱️ Kiri',
                  onTap: () => widget.service.sendMouseClick(button: 'left', count: 1),
                  backgroundColor: const Color(0xFF1A365D),
                  textColor: const Color(0xFF90CDF4),
                ),
                _buildKeyButton(
                  label: '🔘 Tengah',
                  onTap: () => widget.service.sendMouseClick(button: 'middle', count: 1),
                  backgroundColor: const Color(0xFF2D3748),
                  textColor: const Color(0xFFE2E8F0),
                ),
                _buildKeyButton(
                  label: '🖱️ Kanan',
                  onTap: () => widget.service.sendMouseClick(button: 'right', count: 1),
                  backgroundColor: const Color(0xFF4C1D95),
                  textColor: const Color(0xFFDDD6FE),
                ),
              ],
            ),
            const SizedBox(height: 3.0),
          ],

          // ROW 3: CODE SYMBOLS
          Row(
            children: [
              _buildKeyButton(label: '{', onTap: () => widget.service.sendTypeText('{')),
              _buildKeyButton(label: '}', onTap: () => widget.service.sendTypeText('}')),
              _buildKeyButton(label: '[', onTap: () => widget.service.sendTypeText('[')),
              _buildKeyButton(label: ']', onTap: () => widget.service.sendTypeText(']')),
              _buildKeyButton(label: '(', onTap: () => widget.service.sendTypeText('(')),
              _buildKeyButton(label: ')', onTap: () => widget.service.sendTypeText(')')),
              _buildKeyButton(label: ';', onTap: () => widget.service.sendTypeText(';')),
              _buildKeyButton(label: '=>', onTap: () => widget.service.sendTypeText('=>')),
              _buildKeyButton(label: '|', onTap: () => widget.service.sendTypeText('|')),
              _buildKeyButton(label: '"', onTap: () => widget.service.sendTypeText('"')),
              _buildKeyButton(label: "'", onTap: () => widget.service.sendTypeText("'")),
            ],
          ),
          const SizedBox(height: 3.0),

          // ROW 4: ARROW KEYS & EDITING
          Row(
            children: [
              _buildKeyButton(
                label: '⌫ Del',
                onTap: () => widget.service.sendKeyPress('backspace'),
                backgroundColor: const Color(0xFF5C1D24),
              ),
              _buildKeyButton(
                label: _isShiftActive ? 'Sel ←' : '←',
                onTap: () => _handleArrowPress('left'),
                backgroundColor: _isShiftActive ? const Color(0xFF3D2C00) : null,
                textColor: _isShiftActive ? const Color(0xFFFFCC00) : null,
              ),
              _buildKeyButton(
                label: _isShiftActive ? 'Sel ↑' : '↑',
                onTap: () => _handleArrowPress('up'),
                backgroundColor: _isShiftActive ? const Color(0xFF3D2C00) : null,
                textColor: _isShiftActive ? const Color(0xFFFFCC00) : null,
              ),
              _buildKeyButton(
                label: _isShiftActive ? 'Sel ↓' : '↓',
                onTap: () => _handleArrowPress('down'),
                backgroundColor: _isShiftActive ? const Color(0xFF3D2C00) : null,
                textColor: _isShiftActive ? const Color(0xFFFFCC00) : null,
              ),
              _buildKeyButton(
                label: _isShiftActive ? 'Sel →' : '→',
                onTap: () => _handleArrowPress('right'),
                backgroundColor: _isShiftActive ? const Color(0xFF3D2C00) : null,
                textColor: _isShiftActive ? const Color(0xFFFFCC00) : null,
              ),
              _buildKeyButton(
                label: '↩ Undo',
                onTap: () => widget.service.sendShortcut(['ctrl', 'z']),
              ),
              _buildKeyButton(
                label: '↵ Enter',
                onTap: () => widget.service.sendKeyPress('enter'),
                backgroundColor: const Color(0xFF1E3A8A),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

