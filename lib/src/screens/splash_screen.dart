import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import '../widgets/blookit_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoOpacity;
  late Animation<double> _dotsOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _glowOpacity;
  late Animation<double> _screenFade;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    );

    // 0-2 seconds: Logo fade in
    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.285, curve: Curves.easeInOut), // 0-2s
    ));

    // 2-5 seconds: Dots animation
    _dotsOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.285, 0.714, curve: Curves.easeInOut), // 2-5s
    ));

    // 5-7 seconds: Logo scale up and glow
    _logoScale = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.714, 1.0, curve: Curves.easeOut), // 5-7s
    ));

    _glowOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.714, 1.0, curve: Curves.easeOut), // 5-7s
    ));

    // Final screen fade out
    _screenFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.9, 1.0, curve: Curves.easeInOut), // 6.3-7s
    ));

    _controller.forward().then((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _screenFade.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: AspectRatio(
                aspectRatio: 9 / 16, // 1080x1920 portrait
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with glow effect
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow effect
                          AnimatedBuilder(
                            animation: _glowOpacity,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _glowOpacity.value,
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0x40FF5F6D),
                                        Color(0x40FFC371),
                                        Colors.transparent,
                                      ],
                                      stops: [0.0, 0.7, 1.0],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Logo
                          AnimatedBuilder(
                            animation: Listenable.merge([_logoOpacity, _logoScale]),
                            builder: (context, child) {
                              return Opacity(
                                opacity: _logoOpacity.value,
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: const BlookitLogo(
                                    size: 140,
                                    borderRadius: 0, // Square shape
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // App name
                      AnimatedBuilder(
                        animation: _logoOpacity,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _logoOpacity.value,
                            child: const Text(
                              'blookit',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3748),
                                letterSpacing: 1.2,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Three dots loading animation
                      AnimatedBuilder(
                        animation: _dotsOpacity,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _dotsOpacity.value * (1 - (_controller.value > 0.714 ? (_controller.value - 0.714) / 0.286 : 0)),
                            child: SizedBox(
                              height: 20,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  return AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, child) {
                                      double animationValue = (_controller.value - 0.285) / 0.429; // 2-5s normalized
                                      if (animationValue < 0) animationValue = 0;
                                      if (animationValue > 1) animationValue = 1;
                                      
                                      // Create a repeating cycle for dots
                                      double cycleValue = (animationValue * 4) % 1.0;
                                      double dotDelay = index * 0.2;
                                      double dotOpacity = 0.3;
                                      
                                      if (cycleValue > dotDelay && cycleValue < dotDelay + 0.4) {
                                        dotOpacity = 1.0;
                                      }
                                      
                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFA0A0A0).withOpacity(dotOpacity),
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}