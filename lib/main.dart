import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/screens/splash_screen.dart';
import 'src/providers/chat_provider.dart';
import 'src/providers/notification_provider.dart';

void main() {
  runApp(const BlookitApp());
}

class BlookitApp extends StatelessWidget {
  const BlookitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
      title: 'Blookit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        primaryColor: const Color(0xFFFF5F6D),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Inter', // Using Inter as specified
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Color(0xFF1A202C),
            fontWeight: FontWeight.w700,
          ),
          displayMedium: TextStyle(
            color: Color(0xFF1A202C),
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF1A202C),
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF718096),
            fontWeight: FontWeight.w400,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF5F6D), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFFF7FAFC),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      ),
    );
  }
}