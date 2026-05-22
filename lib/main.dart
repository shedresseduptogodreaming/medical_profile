import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
  url: 'https://obbcgffimkgwgwdzuqrj.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9iYmNnZmZpbWtnd2d3ZHp1cXJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzNzg3MTIsImV4cCI6MjA5NDk1NDcxMn0.B4OZY4PAzARLt0-U7UHVWjJZZ70ynU3r1xq6RKa1xgU',
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.implicit,
  ),
);
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