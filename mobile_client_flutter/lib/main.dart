import 'package:flutter/material.dart';
import 'views/connect_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DevControlApp());
}

class DevControlApp extends StatelessWidget {
  const DevControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevControl Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0C10),
        primaryColor: const Color(0xFF00F0FF),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ConnectScreen(),
      },
    );
  }
}
