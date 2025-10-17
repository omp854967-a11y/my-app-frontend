import 'package:flutter/material.dart';

class BlookitLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool circular;
  final List<Color> colors;

  const BlookitLogo({
    super.key,
    this.size = 32,
    this.borderRadius = 0,
    this.circular = false,
    this.colors = const [Color(0xFFFF5F6D), Color(0xFFFFC371)],
  });

  @override
  Widget build(BuildContext context) {
    return Container
    (
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: circular ? null : BorderRadius.circular(borderRadius),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'b',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}