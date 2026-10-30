import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _backgroundController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToMenu();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _logoController.forward();
    _backgroundController.repeat();
    _particleController.repeat();
  }

  void _navigateToMenu() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MenuScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated futuristic background
          AnimatedBuilder(
            animation: Listenable.merge([_backgroundController, _particleController]),
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black,
                      Colors.grey.shade900,
                      Colors.cyan.shade900.withOpacity(0.4),
                      Colors.black,
                    ],
                    stops: [
                      0.0,
                      0.3 + _backgroundController.value * 0.1,
                      0.7 + _backgroundController.value * 0.1,
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),

          // Futuristic grid and particle overlay
          CustomPaint(
            painter: GravBlastSplashPainter(
              backgroundAnimation: _backgroundController,
              particleAnimation: _particleController,
            ),
            size: Size.infinite,
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game logo with futuristic design
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
                  child: CustomPaint(
                    painter: GravBlastLogoPainter(),
                    size: const Size(100, 100),
                  ),
                ).animate(controller: _logoController)
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.elasticOut,
                    duration: 1200.ms,
                  )
                  .then()
                  .shimmer(
                    duration: 1500.ms,
                    color: Colors.cyan.withOpacity(0.5),
                  ),

                const SizedBox(height: 40),

                // Game title with futuristic styling
                const Text(
                  'GRAV',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 8,
                    shadows: [
                      Shadow(
                        color: Colors.cyan,
                        offset: Offset(0, 0),
                        blurRadius: 15,
                      ),
                      Shadow(
                        color: Colors.cyan,
                        offset: Offset(3, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ).animate()
                  .fadeIn(delay: 600.ms, duration: 800.ms)
                  .slideY(begin: 0.3, end: 0)
                  .then()
                  .shimmer(
                    duration: 2000.ms,
                    color: Colors.cyan.withOpacity(0.3),
                  ),

                const Text(
                  'BLAST',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 8,
                    shadows: [
                      Shadow(
                        color: Colors.cyan,
                        offset: Offset(0, 0),
                        blurRadius: 15,
                      ),
                      Shadow(
                        color: Colors.cyan,
                        offset: Offset(3, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ).animate()
                  .fadeIn(delay: 800.ms, duration: 800.ms)
                  .slideY(begin: 0.3, end: 0)
                  .then()
                  .shimmer(
                    duration: 2000.ms,
                    color: Colors.cyan.withOpacity(0.3),
                  ),

                const SizedBox(height: 24),

                // Subtitle with futuristic feel
                const Text(
                  'Clear • Blast • Dominate',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.cyanAccent,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  ),
                ).animate()
                  .fadeIn(delay: 1200.ms, duration: 600.ms),

                const SizedBox(height: 64),

                // Futuristic loading indicator
                Container(
                  width: 250,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.cyan.withOpacity(0.2),
                  ),
                  child: AnimatedBuilder(
                    animation: _backgroundController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                        value: (_backgroundController.value * 3) % 1.0,
                      );
                    },
                  ),
                ).animate()
                  .fadeIn(delay: 1600.ms, duration: 400.ms),

                const SizedBox(height: 16),

                const Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.cyan,
                    letterSpacing: 1,
                  ),
                ).animate()
                  .fadeIn(delay: 1800.ms, duration: 400.ms)
                  .then()
                  .shimmer(
                    duration: 1500.ms,
                    color: Colors.white.withOpacity(0.5),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the Grav Blast logo - 3x3 grid with pattern
class GravBlastLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.8);
    
    // 3x3 grid setup
    final cellSize = size.width / 3;
    final padding = cellSize * 0.1;
    
    // Pattern: fill cells to create an interesting shape
    // This creates a cross-like pattern with corners
    final filledCells = [
      [true, false, true],    // Top row: corners filled
      [false, true, false],   // Middle row: center filled
      [true, false, true],    // Bottom row: corners filled
    ];
    
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final x = col * cellSize;
        final y = row * cellSize;
        final rect = Rect.fromLTWH(
          x + padding, 
          y + padding, 
          cellSize - padding * 2, 
          cellSize - padding * 2
        );
        
        // Fill the cell if it's in our pattern
        if (filledCells[row][col]) {
          paint.color = Colors.cyan;
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            paint,
          );
        }
        
        // Draw border for all cells
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          strokePaint,
        );
      }
    }
    
    // Add some glow effect around filled cells
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.cyan.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        if (filledCells[row][col]) {
          final x = col * cellSize;
          final y = row * cellSize;
          final rect = Rect.fromLTWH(
            x + padding - 2, 
            y + padding - 2, 
            cellSize - padding * 2 + 4, 
            cellSize - padding * 2 + 4
          );
          
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(6)),
            glowPaint,
          );
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GravBlastSplashPainter extends CustomPainter {
  final Animation<double> backgroundAnimation;
  final Animation<double> particleAnimation;

  GravBlastSplashPainter({
    required this.backgroundAnimation,
    required this.particleAnimation,
  }) : super(repaint: Listenable.merge([backgroundAnimation, particleAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final time = backgroundAnimation.value * 2 * pi;
    final particleTime = particleAnimation.value * 2 * pi;

    // Draw animated grid lines (futuristic feel)
    _drawFuturisticGrid(canvas, size, time);
    
    // Draw floating particles
    _drawEnergyParticles(canvas, size, particleTime);
    
    // Draw central energy rings
    _drawEnergyRings(canvas, centerX, centerY, time);
    
    // Draw gravity wells (theme appropriate)
    _drawGravityWells(canvas, size, time);
  }

  void _drawFuturisticGrid(Canvas canvas, Size size, double time) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final spacing = 60.0;
    final offset = (time * 8) % spacing;

    // Vertical lines with subtle animation
    for (double x = -offset; x < size.width + spacing; x += spacing) {
      final alpha = (sin(time + x / 100) + 1) * 0.1;
      paint.color = Colors.cyan.withOpacity(alpha);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines with subtle animation
    for (double y = -offset; y < size.height + spacing; y += spacing) {
      final alpha = (sin(time + y / 100) + 1) * 0.1;
      paint.color = Colors.cyan.withOpacity(alpha);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawEnergyParticles(Canvas canvas, Size size, double time) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // More particles for energy feel
    for (int i = 0; i < 50; i++) {
      final x = (i * 67 + time * 25) % size.width;
      final y = (i * 53 + time * 18) % size.height;
      final radius = 1.0 + (i % 4) * 0.5;
      final alpha = (sin(time + i * 0.5) + 1) * 0.4;

      // Alternating cyan and white particles
      final color = i % 3 == 0 
          ? Colors.white.withOpacity(alpha)
          : Colors.cyan.withOpacity(alpha);
      
      paint.color = color;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _drawEnergyRings(Canvas canvas, double centerX, double centerY, double time) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int ring = 0; ring < 4; ring++) {
      final radius = 120 + ring * 60;
      final sides = 8 + ring * 2;
      final rotation = time / (ring + 1);
      final alpha = (sin(time + ring * 1.5) + 1) * 0.15;

      paint.color = Colors.cyan.withOpacity(alpha);

      final path = Path();
      for (int i = 0; i <= sides; i++) {
        final angle = (i / sides) * 2 * pi + rotation;
        final x = centerX + radius * cos(angle);
        final y = centerY + radius * sin(angle);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  void _drawGravityWells(Canvas canvas, Size size, double time) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw gravity well effects in corners
    final corners = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width * 0.3, size.height * 0.8),
      Offset(size.width * 0.7, size.height * 0.2),
    ];

    for (int i = 0; i < corners.length; i++) {
      final center = corners[i];
      final phase = time + i * pi / 2;
      
      for (int ring = 1; ring <= 3; ring++) {
        final radius = 20 + ring * 15 + sin(phase + ring) * 5;
        final alpha = (sin(phase + ring * 0.5) + 1) * 0.1;
        
        paint.color = Colors.cyan.withOpacity(alpha);
        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}