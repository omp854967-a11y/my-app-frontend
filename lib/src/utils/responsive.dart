import 'package:flutter/material.dart';

class Responsive {
  // Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Android 360dp x 640dp specifications
  static bool isAndroid360(BuildContext context) {
    return screenWidth(context) <= 360;
  }

  // Exact Android measurements in dp (converted to logical pixels) - Much More Compact
  
  // Top App Bar: Much more compact
  static double appBarHeight(BuildContext context) {
    return 45.0; // Significantly reduced for more content space
  }

  // Bottom Navigation: More compact
  static double bottomNavHeight(BuildContext context) {
    return 55.0; // Reduced for more screen space
  }

  // Search and Notification touch targets: Compact
  static double touchTargetSize(BuildContext context) {
    return 38.0; // Reduced for more compact header
  }

  // Logo size: Smaller
  static double logoSize(BuildContext context) {
    return 22.0; // Much smaller for compact design
  }

  // Navigation icons: Compact touch target
  static double navIconTouchTarget(BuildContext context) {
    return 48.0; // Reduced for compact navigation
  }

  // Navigation icon size: Smaller
  static double navIconSize(BuildContext context) {
    return 20.0; // Much smaller for cleaner look
  }

  // Basic responsive utilities

  // Typography and sizing utilities

  // Available content height (screen - app bar - bottom nav)
  static double availableContentHeight(BuildContext context) {
    return screenHeight(context) - appBarHeight(context) - bottomNavHeight(context);
  }
}