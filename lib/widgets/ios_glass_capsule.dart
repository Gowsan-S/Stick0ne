import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Authentic iOS 18 liquidmorphism glass capsule widget matching the Apple App Library search bar
/// and floating system controls with dual-specular gradient meniscus rims, frosted optical blur,
/// and luminous surface gradients.
class IosGlassCapsule extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double blurSigma;
  final bool showTopSheen;
  final List<Color>? gradientColors;
  final List<double>? gradientStops;
  final double borderWidth;
  final List<Color>? borderColors;
  final List<double>? borderStops;
  final List<BoxShadow>? shadows;

  const IosGlassCapsule({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.radius = 100, // stadium capsule by default
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.blurSigma = 26,
    this.showTopSheen = true,
    this.gradientColors,
    this.gradientStops,
    this.borderWidth = 1.2,
    this.borderColors,
    this.borderStops,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Dual-specular meniscus border colors (Crisp 95% white top rim, fading to sides, 50% bottom refraction)
    final effectiveBorderColors = borderColors ??
        const [
          Color(0xF2FFFFFF), // 95% crisp white top specular rim
          Color(0x66FFFFFF), // 40% translucent mid rim
          Color(0x26FFFFFF), // 15% clear optical side
          Color(0x80FFFFFF), // 50% bottom luminous meniscus refraction
        ];

    final effectiveBorderStops = borderStops ?? const [0.0, 0.25, 0.7, 1.0];

    // 2. Liquid glass frosted surface gradient
    final effectiveGradientColors = gradientColors ??
        const [
          Color(0x47FFFFFF), // Luminous top specular glass sheen (28%)
          Color(0x21FFFFFF), // Frosted optical body (13%)
          Color(0x12FFFFFF), // Clear depth (7%)
          Color(0x24FFFFFF), // Bottom meniscus light bounce (14%)
        ];

    final effectiveGradientStops =
        gradientStops ?? const [0.0, 0.35, 0.8, 1.0];

    // 3. Ambient glass shadows & outer light halo
    final effectiveShadows = shadows ??
        const [
          BoxShadow(
            color: Color(0x59000000), // Deep ambient shadow
            blurRadius: 24,
            spreadRadius: -2,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x1AFFFFFF), // Ambient perimeter glass halo
            blurRadius: 1.5,
            spreadRadius: 0.5,
          ),
        ];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: CustomPaint(
            painter: _GlassMeniscusPainter(
              radius: radius,
              strokeWidth: borderWidth,
              colors: effectiveBorderColors,
              stops: effectiveBorderStops,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: effectiveGradientColors,
                  stops: effectiveGradientStops,
                ),
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (showTopSheen)
                    Positioned(
                      top: 0,
                      left: radius > 20 ? radius * 0.35 : 12,
                      right: radius > 20 ? radius * 0.35 : 12,
                      child: Container(
                        height: 1.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0x80FFFFFF),
                              Color(0xD9FFFFFF),
                              Color(0x80FFFFFF),
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassMeniscusPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final List<Color> colors;
  final List<double> stops;

  _GlassMeniscusPainter({
    required this.radius,
    required this.strokeWidth,
    required this.colors,
    required this.stops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokeWidth <= 0) return;
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(math.max(0, radius - inset)),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: stops,
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassMeniscusPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.colors != colors ||
        oldDelegate.stops != stops;
  }
}
