import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'dart:ui';
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
      extendBody: true,
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Platform.isIOS ? _buildIOSTabBar() : _buildAndroidTabBar(),
          ),
        ],
      ),
    );
  }

  // твой оригинальный CNTabBar без изменений
  Widget _buildIOSTabBar() {
    return CNTabBar(
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
    );
  }

  
  Widget _buildAndroidTabBar() {
  return Padding(
    padding: EdgeInsets.only(
      left: 100,
      right: 100,
      bottom: MediaQuery.of(context).padding.bottom + 12,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAndroidTab(0, Icons.qr_code_scanner_outlined, Icons.qr_code_scanner, 'Главная'),
              const SizedBox(width: 8), // регулируй это значение
              _buildAndroidTab(1, Icons.person_outline, Icons.person, 'Профиль'),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildAndroidTab(int index, IconData icon, IconData activeIcon, String label) {
  final isActive = _selectedIndex == index;

  return GestureDetector(
    onTap: () => setState(() => _selectedIndex = index),
    behavior: HitTestBehavior.opaque,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.black.withOpacity(0.35) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isActive ? activeIcon : icon,
              key: ValueKey(isActive),
              color: isActive ? Colors.white : Colors.white54,
              size: 22,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.white : Colors.white54,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(label),
          ),
        ],
      ),
    ),
  );
}
}