import 'package:flutter/material.dart';
import 'blookit_logo.dart';

class GradientHeader extends StatelessWidget {
  final VoidCallback? onNotifications;
  final VoidCallback? onSearch;
  
  const GradientHeader({
    super.key,
    this.onNotifications,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48, // 48dp very compact Android height
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF6F61), // Orange
            Color(0xFFFF8C5A), // Light Orange
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16), // 16dp corner radius
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8, // 4dp elevation = ~8px blur
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12), // 12dp horizontal padding (compact)
          child: Row(
            children: [
              // Left: Search icon
              Container(
                width: 32,
                height: 32,
                child: IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: onSearch,
                  padding: EdgeInsets.zero,
                ),
              ),
              
              // Center: Blookit Logo
              const Spacer(),
              Container(
                width: 24, // Much smaller logo
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF6B9D), // Pink (same as splash screen)
                      Color(0xFFFF8E53), // Orange (same as splash screen)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6), // Rounded corners like splash screen
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'b',
                    style: TextStyle(
                      color: Colors.white, // White text like splash screen
                      fontSize: 14, // Much smaller font
                      fontWeight: FontWeight.w600, // Same weight as splash screen
                      fontFamily: 'SF Pro Display', // Same font as splash screen
                    ),
                  ),
                ),
              ),
              
              // Right spacer to center the logo
              const Spacer(),
              
              // Right: Notification icon
              Container(
                width: 32, // Much smaller touch target
                height: 32,
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white, // White notification icon
                    size: 18, // 18dp icon size (much smaller)
                  ),
                  onPressed: onNotifications,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}