import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/devcontrol_service.dart';

class ScreenViewer extends StatelessWidget {
  final DevControlService service;

  const ScreenViewer({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Uint8List>(
      stream: service.frameStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF00F0FF)),
                SizedBox(height: 12),
                Text(
                  "Receiving screen stream...",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Image.memory(
          snapshot.data!,
          gaplessPlayback: true, // Prevents flicker between compressed frames
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        );
      },
    );
  }
}
