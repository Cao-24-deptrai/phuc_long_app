import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PhucLongLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;
  final bool isLight;

  const PhucLongLogo({
    super.key,
    this.size = 60,
    this.showText = true,
    this.color,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? (isLight ? Colors.white : const Color(0xFF0C5A30));
    final textColor = isLight ? Colors.white : const Color(0xFF0C5A30);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Custom Painted Leaf inside Circle
        CustomPaint(
          size: Size(size, size),
          painter: _LogoPainter(color: logoColor),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PHÚC LONG',
                style: GoogleFonts.playfairDisplay(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: textColor,
                ),
              ),
              Text(
                'TEA & COFFEE',
                style: GoogleFonts.outfit(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: isLight ? Colors.white70 : const Color(0xFFB89047), // Gold accent
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;

  _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - paint.strokeWidth;

    // Draw Outer Circle
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius, fillPaint);

    // Draw Inner Circle (thin)
    final innerPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.015
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius * 0.85, innerPaint);

    // Draw Stylized Tea Leaf inside the circle
    final leafPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    
    // Draw a leaf shape in the center
    // Centered leaf coordinates relative to size
    final w = size.width;
    final h = size.height;

    // Start at bottom left of the leaf
    path.moveTo(w * 0.35, h * 0.65);
    
    // Top-right tip of the leaf
    path.cubicTo(
      w * 0.30, h * 0.35, // Control point 1
      w * 0.50, h * 0.25, // Control point 2
      w * 0.68, h * 0.32, // End point
    );
    
    // Back to bottom left
    path.cubicTo(
      w * 0.70, h * 0.55, // Control point 1
      w * 0.55, h * 0.70, // Control point 2
      w * 0.35, h * 0.65, // End point
    );

    canvas.drawPath(path, leafPaint);

    // Draw leaf veins (in white/contrast color)
    final veinPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final veinPath = Path();
    // Center vein
    veinPath.moveTo(w * 0.38, h * 0.62);
    veinPath.quadraticBezierTo(w * 0.52, h * 0.48, w * 0.66, h * 0.34);

    // Secondary veins
    veinPath.moveTo(w * 0.46, h * 0.54);
    veinPath.lineTo(w * 0.42, h * 0.46);

    veinPath.moveTo(w * 0.52, h * 0.48);
    veinPath.lineTo(w * 0.60, h * 0.52);

    veinPath.moveTo(w * 0.56, h * 0.44);
    veinPath.lineTo(w * 0.52, h * 0.36);

    canvas.drawPath(veinPath, veinPaint);

    // Draw small stem
    final stemPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawLine(
      Offset(w * 0.35, h * 0.65),
      Offset(w * 0.28, h * 0.72),
      stemPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
