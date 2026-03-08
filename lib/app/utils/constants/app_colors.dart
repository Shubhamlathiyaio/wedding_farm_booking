import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppColors {
  AppColors._();

  static Color get primary => Get.isDarkMode ? const Color(0xFFFF9800) : const Color(0xFFE65100);
  static Color get primaryLight => Get.isDarkMode ? const Color(0xFF422100) : const Color(0xFFFFF3E0);
  static Color get error => const Color(0xFFD32F2F);
  static Color get background => Get.isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
  static Color get textPrimary => Get.isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A);
  static Color get textSecondary => Get.isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF6B7280);
  static Color get white => const Color(0xFFFFFFFF);
  static Color get black => const Color(0xFF000000);
  static Color get grey => const Color(0xFF9E9E9E);
  static Color get greyLight => Get.isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
  static Color get pending => const Color(0xFFF57C00);
  static Color get tokenPaid => const Color(0xFFE65100);
  static Color get released => const Color(0xFF9E9E9E);
  static Color get approved => const Color(0xFF43A047);
  static Color get divider => Get.isDarkMode ? const Color(0xFF383838) : const Color(0xFFE0E0E0);
  static Color get cardShadow => Get.isDarkMode ? const Color(0x4D000000) : const Color(0x1A000000);
  static Color get cardBackground => Get.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
}
