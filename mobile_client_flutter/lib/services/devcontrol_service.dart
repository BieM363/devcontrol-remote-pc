import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


class DevControlService {
  WebSocketChannel? _channel;
  String? _authToken;
  int _screenWidth = 1920;
  int _screenHeight = 1080;
  
  final _frameStreamController = StreamController<Uint8List>.broadcast();
  final _authResultController = StreamController<Map<String, dynamic>>.broadcast();
  final _pongController = StreamController<int>.broadcast();

  Stream<Uint8List> get frameStream => _frameStreamController.stream;
  Stream<Map<String, dynamic>> get authStream => _authResultController.stream;
  Stream<int> get pongStream => _pongController.stream;

  int get screenWidth => _screenWidth;
  int get screenHeight => _screenHeight;
  bool get isConnected => _channel != null;

  Future<void> connect(String wsUrl, String pin) async {
    try {
      disconnect();
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          if (message is String) {
            try {
              final data = jsonDecode(message);
              _handleJsonMessage(data);
            } catch (e) {
              debugPrint("JSON Decode Error: $e");
            }
          } else if (message is Uint8List) {
            _frameStreamController.add(message);
          } else if (message is List<int>) {
            _frameStreamController.add(Uint8List.fromList(message));
          } else if (message is ByteBuffer) {
            _frameStreamController.add(message.asUint8List());
          } else if (message is ByteData) {
            _frameStreamController.add(message.buffer.asUint8List());
          } else {
            debugPrint("Received unhandled binary frame type: ${message.runtimeType}");
          }
        },

        onError: (error) {
          debugPrint("WebSocket Error: $error");
          _authResultController.add({
            'success': false,
            'message': 'Tidak dapat terhubung ke Server / Tunnel Cloudflare!',
          });
          disconnect();
        },
        onDone: () {
          debugPrint("WebSocket Connection Closed");
          _authResultController.add({
            'success': false,
            'message': 'Koneksi ditutup oleh Server / Link Tunnel.',
          });
          disconnect();
        },
      );


      // Send Auth Handshake
      final authPayload = {
        'type': 'auth',
        'pin': pin,
        'client_id': 'zte_blade_v50_flutter',
      };
      _channel!.sink.add(jsonEncode(authPayload));
    } catch (e) {
      debugPrint("Connection failed: $e");
      _authResultController.add({
        'success': false,
        'message': 'Format URL tidak valid atau Gagal Koneksi!',
      });
      rethrow;
    }
  }

  void _handleJsonMessage(Map<String, dynamic> msg) {
    final type = msg['type'];
    if (type == 'auth_result') {
      if (msg['success'] == true) {
        _authToken = msg['token'];
        _screenWidth = msg['screen_width'] ?? 1920;
        _screenHeight = msg['screen_height'] ?? 1080;
      }
      _authResultController.add(msg);
    } else if (type == 'pong') {
      final sentTime = msg['timestamp'] as int? ?? 0;
      final pingMs = DateTime.now().millisecondsSinceEpoch - sentTime;
      _pongController.add(pingMs);
    }
  }

  void sendControl(Map<String, dynamic> data) {
    if (_channel != null && _authToken != null) {
      data['token'] = _authToken;
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void sendMouseMove(double nx, double ny) {
    sendControl({
      'type': 'mouse_move',
      'nx': nx,
      'ny': ny,
    });
  }

  void sendMouseMoveRel(int dx, int dy) {
    sendControl({
      'type': 'mouse_move_rel',
      'dx': dx,
      'dy': dy,
    });
  }

  void sendMouseDown({String button = 'left'}) {
    sendControl({
      'type': 'mouse_down',
      'button': button,
    });
  }

  void sendMouseUp({String button = 'left'}) {
    sendControl({
      'type': 'mouse_up',
      'button': button,
    });
  }

  void sendMouseClick({String button = 'left', int count = 1}) {
    sendControl({
      'type': 'mouse_click',
      'button': button,
      'count': count,
    });
  }

  void sendMouseScroll(int dx, int dy) {
    sendControl({
      'type': 'mouse_scroll',
      'dx': dx,
      'dy': dy,
    });
  }

  void sendShortcut(List<String> keys) {
    sendControl({
      'type': 'shortcut',
      'keys': keys,
    });
  }

  void sendKeyPress(String key) {
    sendControl({
      'type': 'key_press',
      'key': key,
    });
  }

  void sendTypeText(String text) {
    sendControl({
      'type': 'type_text',
      'text': text,
    });
  }

  void sendSettings({int? targetWidth, int? quality}) {
    final Map<String, dynamic> payload = {'type': 'settings'};
    if (targetWidth != null) payload['target_width'] = targetWidth;
    if (quality != null) payload['quality'] = quality;
    sendControl(payload);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _authToken = null;
  }

  void dispose() {
    disconnect();
    _frameStreamController.close();
    _authResultController.close();
    _pongController.close();
  }
}
