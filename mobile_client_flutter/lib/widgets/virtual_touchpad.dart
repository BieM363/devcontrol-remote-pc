import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/devcontrol_service.dart';

enum TouchpadMode { directTouch, relativeTrackpad }

class VirtualTouchpad extends StatefulWidget {
  final DevControlService service;
  final TouchpadMode mode;

  const VirtualTouchpad({
    super.key,
    required this.service,
    this.mode = TouchpadMode.directTouch,
  });

  @override
  State<VirtualTouchpad> createState() => _VirtualTouchpadState();
}

class _VirtualTouchpadState extends State<VirtualTouchpad> {
  int _pointerCount = 0;
  Offset? _pointerDownPos;
  DateTime? _pointerDownTime;
  Offset? _lastPointerPos;
  bool _isDragging = false;
  double _scrollAccumulator = 0;
  DateTime? _lastMouseMoveTime;

  // Calculates normalized (0.0 - 1.0) coordinates accounting for letterbox aspect ratio
  (double, double) _getNormalizedCoords(Offset localPos, Size containerSize) {
    if (containerSize.width <= 0 || containerSize.height <= 0) return (0.0, 0.0);

    final double screenW = (widget.service.screenWidth > 0 ? widget.service.screenWidth : 1920).toDouble();
    final double screenH = (widget.service.screenHeight > 0 ? widget.service.screenHeight : 1080).toDouble();
    final double pcAspect = screenW / screenH;
    final double containerAspect = containerSize.width / containerSize.height;

    double renderedW, renderedH, offsetX, offsetY;

    if (containerAspect > pcAspect) {
      // Container is wider than 16:9 (bars on left/right)
      renderedH = containerSize.height;
      renderedW = renderedH * pcAspect;
      offsetX = (containerSize.width - renderedW) / 2;
      offsetY = 0;
    } else {
      // Container is taller than 16:9 (bars on top/bottom)
      renderedW = containerSize.width;
      renderedH = renderedW / pcAspect;
      offsetX = 0;
      offsetY = (containerSize.height - renderedH) / 2;
    }

    final double nx = ((localPos.dx - offsetX) / renderedW).clamp(0.0, 1.0);
    final double ny = ((localPos.dy - offsetY) / renderedH).clamp(0.0, 1.0);
    return (nx, ny);
  }

  void _sendThrottledMouseMove(double nx, double ny) {
    final now = DateTime.now();
    if (_lastMouseMoveTime == null || now.difference(_lastMouseMoveTime!).inMilliseconds > 15) {
      _lastMouseMoveTime = now;
      widget.service.sendMouseMove(nx, ny);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            _pointerCount++;
            _lastPointerPos = event.localPosition;

            if (_pointerCount == 1) {
              _pointerDownPos = event.localPosition;
              _pointerDownTime = DateTime.now();
              _isDragging = false;
              _scrollAccumulator = 0;

              if (widget.mode == TouchpadMode.directTouch) {
                final (nx, ny) = _getNormalizedCoords(event.localPosition, containerSize);
                widget.service.sendMouseMove(nx, ny);
              }
            }
          },
          onPointerMove: (event) {
            if (_lastPointerPos == null) {
              _lastPointerPos = event.localPosition;
              return;
            }

            if (_pointerCount >= 2) {
              // Two finger scrolling (Pulling down = positive dy in Flutter = scroll up in standard gesture)
              final dy = event.localPosition.dy - _lastPointerPos!.dy;
              _scrollAccumulator += dy;
              if (_scrollAccumulator.abs() > 12) {
                final scrollSteps = (_scrollAccumulator / 12).round();
                widget.service.sendMouseScroll(0, scrollSteps);
                _scrollAccumulator = 0;
              }
            } else if (_pointerCount == 1) {
              final distance = _pointerDownPos != null
                  ? (event.localPosition - _pointerDownPos!).distance
                  : 0.0;

              if (distance > 5.0) {
                _isDragging = true;
              }

              if (widget.mode == TouchpadMode.directTouch) {
                final (nx, ny) = _getNormalizedCoords(event.localPosition, containerSize);
                _sendThrottledMouseMove(nx, ny);
              } else {
                final dx = (event.localPosition.dx - _lastPointerPos!.dx) * 1.5;
                final dy = (event.localPosition.dy - _lastPointerPos!.dy) * 1.5;
                widget.service.sendMouseMoveRel(dx.round(), dy.round());
              }
            }
            _lastPointerPos = event.localPosition;
          },
          onPointerUp: (event) {
            _pointerCount = (_pointerCount - 1).clamp(0, 10);

            if (_pointerCount == 0 && _pointerDownPos != null && _pointerDownTime != null) {
              final duration = DateTime.now().difference(_pointerDownTime!);
              final distance = (event.localPosition - _pointerDownPos!).distance;

              if (!_isDragging && distance < 10.0) {
                if (duration.inMilliseconds < 450) {
                  // Single Tap = Immediate Left Click
                  HapticFeedback.selectionClick();
                  final (nx, ny) = _getNormalizedCoords(event.localPosition, containerSize);
                  widget.service.sendMouseMove(nx, ny);
                  widget.service.sendMouseClick(button: 'left', count: 1);
                } else {
                  // Long Press = Right Click (Context Menu)
                  HapticFeedback.heavyImpact();
                  final (nx, ny) = _getNormalizedCoords(event.localPosition, containerSize);
                  widget.service.sendMouseMove(nx, ny);
                  widget.service.sendMouseClick(button: 'right', count: 1);
                }
              }

              _pointerDownPos = null;
              _pointerDownTime = null;
              _isDragging = false;
              _lastPointerPos = null;
              _scrollAccumulator = 0;
            }
          },
          onPointerCancel: (event) {
            _pointerCount = 0;
            _pointerDownPos = null;
            _pointerDownTime = null;
            _isDragging = false;
            _lastPointerPos = null;
            _scrollAccumulator = 0;
          },
          child: Container(
            color: Colors.transparent,
          ),
        );
      },
    );
  }
}
