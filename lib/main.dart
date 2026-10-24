import 'package:flutter/material.dart';
import 'views/jogo_screen.dart';

void main() {
  runApp(const LabirintoApp());
}

class LabirintoApp extends StatelessWidget {
  const LabirintoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'O Labirinto Vivo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101510),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC99A45),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const JogoScreen(),
    );
  }
}