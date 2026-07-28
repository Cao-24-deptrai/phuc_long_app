import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShimmerBanner extends StatefulWidget {
  final double height;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  const ShimmerBanner({
    super.key,
    this.height = 180,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  @override
  State<ShimmerBanner> createState() => _ShimmerBannerState();
}

class _ShimmerBannerState extends State<ShimmerBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Dark forest green background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF07381E),
                    Color(0xFF0C5A30),
                    Color(0xFF137A43),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            
            // Abstract geometric background lines
            Positioned.fill(
              child: CustomPaint(
                painter: _BannerBackgroundPainter(),
              ),
            ),

            // Shimmering / Glowing light overlay sweeping across
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final alignmentValue = -2.0 + (_controller.value * 4.0);
                
                return Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(alignmentValue - 0.5, -1.0),
                        end: Alignment(alignmentValue + 0.5, 1.0),
                        colors: const [
                          Colors.transparent,
                          Colors.transparent,
                          Color(0x05FFFFFF),
                          Color(0x33FFFFFF),
                          Color(0x55FFFFFF),
                          Color(0x33FFFFFF), 
                          Color(0x05FFFFFF),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.35, 0.42, 0.47, 0.50, 0.53, 0.58, 0.65, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Content
            Padding(
              // Giảm padding dọc từ 20 xuống 12 để tránh lỗi overflow
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB89047).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: const Color(0xFFB89047).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'SPECIAL PROMOTION',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE5C07B),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8), // Giảm từ 12 xuống 8
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4), // Giảm từ 6 xuống 4
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 12), // Giảm từ 16 xuống 12
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          child: InkWell(
                            onTap: widget.onTap,
                            borderRadius: BorderRadius.circular(30),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.buttonText,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0C5A30),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: Color(0xFF0C5A30),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Decorative Cup/Art Illustration (Right Side)
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow circle
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFB89047)
                                          .withOpacity(0.15 + 0.1 * (1.0 - _controller.value)),
                                      blurRadius: 15 + 10 * _controller.value,
                                      spreadRadius: 2 + 5 * _controller.value,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          // Cup icon container
                          Container(
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.local_cafe_outlined,
                                color: Color(0xFFE5C07B),
                                size: 35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Draw concentric circles in the background
    path.addOval(Rect.fromCircle(
        center: Offset(size.width * 0.8, size.height * 0.5),
        radius: size.width * 0.2));
    path.addOval(Rect.fromCircle(
        center: Offset(size.width * 0.8, size.height * 0.5),
        radius: size.width * 0.35));
    path.addOval(Rect.fromCircle(
        center: Offset(size.width * 0.8, size.height * 0.5),
        radius: size.width * 0.5));

    // Curved wavy line from bottom-left to top-right
    final wavePath = Path()
      ..moveTo(0, size.height * 0.8)
      ..cubicTo(
        size.width * 0.3, size.height * 0.9,
        size.width * 0.4, size.height * 0.3,
        size.width, size.height * 0.2,
      );

    canvas.drawPath(path, paint);
    canvas.drawPath(
        wavePath,
        paint
          ..color = Colors.white.withOpacity(0.03)
          ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _BannerBackgroundPainter oldDelegate) {
    return false;
  }
}

