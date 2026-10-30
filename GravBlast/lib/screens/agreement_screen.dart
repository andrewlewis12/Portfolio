import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../widgets/terms_of_service_popup.dart';

class AgreementScreen extends StatefulWidget {
  final VoidCallback onAccepted;
  
  const AgreementScreen({
    Key? key,
    required this.onAccepted,
  }) : super(key: key);

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _showAgreementDialog();
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();
  }

  void _showAgreementDialog() {
    // Show the agreement dialog after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => FirstTimeAgreementPopup(
            onAccepted: widget.onAccepted,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey.shade900,
              Colors.cyan.shade900.withOpacity(0.3),
              Colors.black,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background
            AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return CustomPaint(
                  painter: AgreementBackgroundPainter(
                    animation: _backgroundController,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            
            // Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Game logo
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.cyan.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                        border: Border.all(
                          color: Colors.cyan.withOpacity(0.6),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.apps,
                        size: 80,
                        color: Colors.cyan,
                      ),
                    ).animate(controller: _logoController)
                      .scale(
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      )
                      .then()
                      .shimmer(
                        duration: 2000.ms,
                        color: Colors.cyan.withOpacity(0.5),
                      ),
                    
                    const SizedBox(height: 40),
                    
                    // Game title
                    const Text(
                      'GRAV BLAST',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 6,
                        shadows: [
                          Shadow(
                            color: Colors.cyan,
                            offset: Offset(0, 0),
                            blurRadius: 12,
                          ),
                          Shadow(
                            color: Colors.cyan,
                            offset: Offset(2, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ).animate()
                      .fadeIn(delay: 600.ms, duration: 800.ms)
                      .slideY(begin: 0.3, end: 0)
                      .then()
                      .shimmer(
                        duration: 3000.ms,
                        color: Colors.cyan.withOpacity(0.3),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Subtitle
                    const Text(
                      'Clear • Blast • Dominate',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.cyanAccent,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w300,
                      ),
                    ).animate()
                      .fadeIn(delay: 1000.ms, duration: 600.ms),
                    
                    const SizedBox(height: 80),
                    
                    // Welcome message
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.cyan.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.handshake,
                            color: Colors.cyan,
                            size: 32,
                          ).animate()
                            .scale(delay: 1400.ms, duration: 600.ms),
                          
                          const SizedBox(height: 16),
                          
                          const Text(
                            'Welcome to Grav Blast!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ).animate()
                            .fadeIn(delay: 1600.ms, duration: 400.ms),
                          
                          const SizedBox(height: 12),
                          
                          const Text(
                            'Before we begin your puzzle adventure, please review our Terms of Service and Privacy Policy.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ).animate()
                            .fadeIn(delay: 1800.ms, duration: 400.ms),
                        ],
                      ),
                    ).animate()
                      .slideY(begin: 0.3, delay: 1200.ms, duration: 600.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AgreementBackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  AgreementBackgroundPainter({required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final time = animation.value * 2 * 3.14159;
    
    // Draw subtle floating particles
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (int i = 0; i < 20; i++) {
      final x = (i * 89 + time * 10) % size.width;
      final y = (i * 71 + time * 8) % size.height;
      final radius = 1.0 + (i % 3) * 0.5;
      final alpha = (sin(time + i * 0.5) + 1) * 0.2;
      
      paint.color = Colors.cyan.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    
    // Draw subtle grid lines
    final gridPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.05)
      ..strokeWidth = 1;
    
    final spacing = 80.0;
    final offset = (time * 5) % spacing;
    
    // Vertical lines
    for (double x = -offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    
    // Horizontal lines
    for (double y = -offset; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}