import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/game_data.dart';

class ShapeWidget extends StatefulWidget {
  final PlayerShape shape;
  final double size;
  final bool animate;
  final Color? customColor;
  final bool showGlow;

  const ShapeWidget({
    Key? key,
    required this.shape,
    required this.size,
    this.animate = false,
    this.customColor,
    this.showGlow = true,
  }) : super(key: key);

  @override
  _ShapeWidgetState createState() => _ShapeWidgetState();
}

class _ShapeWidgetState extends State<ShapeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    if (widget.animate) {
      _animationController = AnimationController(
        duration: Duration(milliseconds: 1500),
        vsync: this,
      );

      _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );

      _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.linear),
      );

      _animationController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.customColor ?? GameData.getShapeColor(widget.shape);
    
    if (widget.animate) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 0.05,
              child: _buildShape(color),
            ),
          );
        },
      );
    }
    
    return _buildShape(color);
  }

  Widget _buildShape(Color color) {
    switch (widget.shape) {
      case PlayerShape.circle:
        return _buildCircle(color);
      case PlayerShape.square:
        return _buildSquare(color);
      case PlayerShape.triangle:
        return _buildTriangle(color);
      case PlayerShape.diamond:
        return _buildDiamond(color);
      case PlayerShape.star:
        return _buildStar(color);
      case PlayerShape.hexagon:
        return _buildHexagon(color);
      case PlayerShape.heart:
        return _buildHeart(color);
      case PlayerShape.pentagon:
        return _buildPentagon(color);
    }
  }

  Widget _buildCircle(Color color) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: widget.showGlow ? [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ] : null,
      ),
    );
  }

  Widget _buildSquare(Color color) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(widget.size * 0.1),
        boxShadow: widget.showGlow ? [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ] : null,
      ),
    );
  }

  Widget _buildTriangle(Color color) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: TrianglePainter(
        color: color,
        glowColor: widget.showGlow ? color.withOpacity(0.6) : Colors.transparent,
      ),
    );
  }

  Widget _buildDiamond(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(
        child: Transform.rotate(
          angle: pi / 4,
          alignment: Alignment.center,
          child: Container(
            width: widget.size * 0.7,
            height: widget.size * 0.7,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(widget.size * 0.05),
              boxShadow: widget.showGlow
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStar(Color color) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: StarPainter(
        color: color,
        glowColor: widget.showGlow ? color.withOpacity(0.6) : Colors.transparent,
      ),
    );
  }

  Widget _buildHexagon(Color color) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: HexagonPainter(
        color: color,
        glowColor: widget.showGlow ? color.withOpacity(0.6) : Colors.transparent,
      ),
    );
  }

  Widget _buildHeart(Color color) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: HeartPainter(
        color: color,
        glowColor: widget.showGlow ? color.withOpacity(0.6) : Colors.transparent,
      ),
    );
  }

  Widget _buildPentagon(Color color) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: PentagonPainter(
        color: color,
        glowColor: widget.showGlow ? color.withOpacity(0.6) : Colors.transparent,
      ),
    );
  }

  @override
  void dispose() {
    if (widget.animate) {
      _animationController.dispose();
    }
    super.dispose();
  }
}

// Custom Painters for complex shapes
class TrianglePainter extends CustomPainter {
  final Color color;
  final Color glowColor;

  TrianglePainter({required this.color, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    if (glowColor != Colors.transparent) {
      canvas.drawPath(path, glowPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class StarPainter extends CustomPainter {
  final Color color;
  final Color glowColor;

  StarPainter({required this.color, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.4;

    for (int i = 0; i < 10; i++) {
      final angle = (i * pi) / 5;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + radius * cos(angle - pi / 2);
      final y = center.dy + radius * sin(angle - pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    if (glowColor != Colors.transparent) {
      canvas.drawPath(path, glowPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class HexagonPainter extends CustomPainter {
  final Color color;
  final Color glowColor;

  HexagonPainter({required this.color, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (i * pi) / 3;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    if (glowColor != Colors.transparent) {
      canvas.drawPath(path, glowPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class HeartPainter extends CustomPainter {
  final Color color;
  final Color glowColor;

  HeartPainter({required this.color, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(width / 2, height * 0.25);
    path.cubicTo(width / 2, height * 0.1, width * 0.1, height * 0.1, width * 0.1, height * 0.35);
    path.cubicTo(width * 0.1, height * 0.55, width / 2, height * 0.85, width / 2, height);
    path.cubicTo(width / 2, height * 0.85, width * 0.9, height * 0.55, width * 0.9, height * 0.35);
    path.cubicTo(width * 0.9, height * 0.1, width / 2, height * 0.1, width / 2, height * 0.25);
    path.close();

    if (glowColor != Colors.transparent) {
      canvas.drawPath(path, glowPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PentagonPainter extends CustomPainter {
  final Color color;
  final Color glowColor;

  PentagonPainter({required this.color, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * pi) / 5 - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    if (glowColor != Colors.transparent) {
      canvas.drawPath(path, glowPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}