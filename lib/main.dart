import 'package:flutter/material.dart';
import 'features/auth/auth_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'А — здесь',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8522A),
        ),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}