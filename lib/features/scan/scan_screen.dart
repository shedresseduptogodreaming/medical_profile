import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_logo.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _images = [
    'assets/images/hero.png',
    'assets/images/2.png',
    'assets/images/3.png',
    'assets/images/4.png',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: const AppLogo(),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          ClipRRect(
            child: AspectRatio(
              aspectRatio: 402 / 498,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Image.asset(
                    _images[index],
                    width: double.infinity,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _images.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == index ? 10 : 7,
                height: _currentPage == index ? 10 : 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? AppColors.black
                      : AppColors.grey.withOpacity(0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Я здесь',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                    height: 46 / 44,
                  ),
                ),
                Text(
                  'Когда это важно',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 44,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey,
                    letterSpacing: -2,
                    height: 46 / 44,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}