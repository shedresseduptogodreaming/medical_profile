import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://obbcgffimkgwgwdzuqrj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9iYmNnZmZpbWtnd2d3ZHp1cXJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzNzg3MTIsImV4cCI6MjA5NDk1NDcxMn0.B4OZY4PAzARLt0-U7UHVWjJZZ70ynU3r1xq6RKa1xgU',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  // Проверяем Supabase сессию (обычный вход)
  final Session? supabaseSession = Supabase.instance.client.auth.currentSession;

  // Проверяем Яндекс uid (яндекс вход)
  bool isLoggedIn = supabaseSession != null;
  if (!isLoggedIn) {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getString('yandex_uid') != null;
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Я – здесь',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8522A),
        ),
        useMaterial3: true,
      ),
      home: isLoggedIn ? const HomeScreen() : const AuthScreen(),
    );
  }
}