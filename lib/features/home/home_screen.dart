import 'package:flutter/material.dart';
import 'package:cupertino_native/cupertino_native.dart';
import '../../../core/theme.dart';
import '../scan/scan_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ScanScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CNTabBar(
              split: false,
              shrinkCentered: true,
              tint: AppColors.black,
              items: const [
                CNTabBarItem(
                  label: 'Главная',
                  icon: CNSymbol('qrcode.viewfinder'),
                ),
                CNTabBarItem(
                  label: 'Профиль',
                  icon: CNSymbol('person.crop.circle'),
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
            ),
          ),
        ],
      ),
    );
  }
}