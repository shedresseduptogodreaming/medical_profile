import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const orange = Color(0xFFFE6345);
  static const black = Color(0xFF333333);
  static const grey = Color(0xFFB3B3B3);
  static const white = Colors.white;
}

class AppTextStyles {
  static final buttonText = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
    letterSpacing: -1.5,
  );

  static final subtitle = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.grey,
    letterSpacing: -1.5,
  );

  static final body = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
    letterSpacing: -1.5,
  );

  static final heading = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
    letterSpacing: -1.5,
  );

  static final fieldText = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
    letterSpacing: -1.5,
  );

  static final fieldHint = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.grey,
    letterSpacing: -1.5,
  );
}