import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/sticker_item.dart';

class StickerDisplayWidget extends StatelessWidget {
  final StickerItem sticker;
  final double size;

  const StickerDisplayWidget({
    super.key,
    required this.sticker,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    switch (sticker.type) {
      case StickerType.vector:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _VectorStickerPainter(sticker.data),
          ),
        );

      case StickerType.emoji:
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              sticker.data,
              style: TextStyle(
                fontSize: size * 0.72,
                height: 1.0,
              ),
            ),
          ),
        );

      case StickerType.text:
        return _buildTextSticker();

      case StickerType.image:
        return SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.08),
            child: File(sticker.data).existsSync()
                ? Image.file(
                    File(sticker.data),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        _fallbackIcon(),
                  )
                : _fallbackIcon(),
          ),
        );
    }
  }

  Widget _buildTextSticker() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.16,
        vertical: size * 0.08,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(size * 0.16),
        border: Border.all(
          color: Colors.white,
          width: 2.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        sticker.data,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.22,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.broken_image_rounded,
        size: size * 0.5,
        color: Colors.white54,
      ),
    );
  }
}

class _VectorStickerPainter extends CustomPainter {
  final String vectorId;

  _VectorStickerPainter(this.vectorId);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    switch (vectorId) {
      case 'kawaii_star':
        _drawKawaiiStar(canvas, center, w * 0.42);
        break;
      case 'cute_cloud':
        _drawCuteCloud(canvas, center, w, h);
        break;
      case 'aesthetic_ghost':
        _drawAestheticGhost(canvas, center, w, h);
        break;
      case 'pixel_heart':
        _drawPixelHeart(canvas, center, w * 0.4);
        break;
      case 'cosmic_cat':
        _drawCosmicCat(canvas, center, w, h);
        break;
      case 'retro_tape':
        _drawRetroTape(canvas, center, w, h);
        break;
      case 'cyber_skull':
        _drawCyberSkull(canvas, center, w, h);
        break;
      case 'sunset_wave':
        _drawSunsetWave(canvas, center, w * 0.45);
        break;
      case 'matcha_latte':
        _drawMatchaLatte(canvas, center, w, h);
        break;
      case 'sparkle_badge':
        _drawSparkle(canvas, center, w * 0.42);
        break;
      case 'mushroom_magic':
        _drawMushroom(canvas, center, w, h);
        break;
      case 'lofi_plant':
        _drawLofiPlant(canvas, center, w, h);
        break;
      case 'gameboy_retro':
        _drawGameboy(canvas, center, w, h);
        break;
      case 'neon_crystal':
        _drawNeonCrystal(canvas, center, w, h);
        break;
      default:
        _drawKawaiiStar(canvas, center, w * 0.42);
    }
  }

  void _drawKawaiiStar(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    const points = 5;
    final innerRadius = radius * 0.5;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = (i * math.pi / points) - (math.pi / 2);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // Cute eyes
    final eyePaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawCircle(Offset(center.dx - radius * 0.22, center.dy), 3.5, eyePaint);
    canvas.drawCircle(Offset(center.dx + radius * 0.22, center.dy), 3.5, eyePaint);

    // Blush
    final blushPaint = Paint()..color = const Color(0xFFFF8A80).withOpacity(0.65);
    canvas.drawCircle(Offset(center.dx - radius * 0.35, center.dy + 5), 4, blushPaint);
    canvas.drawCircle(Offset(center.dx + radius * 0.35, center.dy + 5), 4, blushPaint);

    // Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final smilePath = Path()
      ..arcTo(
        Rect.fromCircle(center: Offset(center.dx, center.dy + 2), radius: 6),
        0.2,
        math.pi - 0.4,
        false,
      );
    canvas.drawPath(smilePath, smilePaint);
  }

  void _drawCuteCloud(Canvas canvas, Offset center, double w, double h) {
    final bgPaint = Paint()
      ..color = const Color(0xFFE1F5FE)
      ..style = PaintingStyle.fill;

    final path = Path();
    final r = Rect.fromCenter(center: Offset(center.dx, center.dy + 5), width: w * 0.75, height: h * 0.45);
    path.addRRect(RRect.fromRectAndRadius(r, Radius.circular(h * 0.22)));

    canvas.drawPath(path, bgPaint);
    canvas.drawCircle(Offset(center.dx - w * 0.18, center.dy - 6), w * 0.18, bgPaint);
    canvas.drawCircle(Offset(center.dx + w * 0.12, center.dy - 12), w * 0.22, bgPaint);

    // Eye dots
    final eyePaint = Paint()..color = const Color(0xFF0277BD);
    canvas.drawCircle(Offset(center.dx - 12, center.dy + 4), 3, eyePaint);
    canvas.drawCircle(Offset(center.dx + 12, center.dy + 4), 3, eyePaint);

    // Rosy cheeks
    final blush = Paint()..color = const Color(0xFFF48FB1).withOpacity(0.7);
    canvas.drawCircle(Offset(center.dx - 22, center.dy + 10), 4, blush);
    canvas.drawCircle(Offset(center.dx + 22, center.dy + 10), 4, blush);
  }

  void _drawAestheticGhost(Canvas canvas, Offset center, double w, double h) {
    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(center.dx - w * 0.3, center.dy + h * 0.28);
    path.lineTo(center.dx - w * 0.3, center.dy - h * 0.05);
    path.arcToPoint(
      Offset(center.dx + w * 0.3, center.dy - h * 0.05),
      radius: Radius.circular(w * 0.3),
    );
    path.lineTo(center.dx + w * 0.3, center.dy + h * 0.28);
    // wavy bottom
    path.quadraticBezierTo(center.dx + w * 0.15, center.dy + h * 0.22, center.dx, center.dy + h * 0.28);
    path.quadraticBezierTo(center.dx - w * 0.15, center.dy + h * 0.34, center.dx - w * 0.3, center.dy + h * 0.28);
    path.close();

    canvas.drawPath(path, bodyPaint);
    canvas.drawPath(path, strokePaint);

    // Big anime eyes
    final eyePaint = Paint()..color = const Color(0xFF263238);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 12, center.dy - 6), width: 7, height: 11), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 12, center.dy - 6), width: 7, height: 11), eyePaint);

    // Eye highlights
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(center.dx - 13, center.dy - 8), 2, whitePaint);
    canvas.drawCircle(Offset(center.dx + 11, center.dy - 8), 2, whitePaint);

    // Blush
    final blush = Paint()..color = const Color(0xFFFF80AB).withOpacity(0.6);
    canvas.drawCircle(Offset(center.dx - 22, center.dy + 2), 4, blush);
    canvas.drawCircle(Offset(center.dx + 22, center.dy + 2), 4, blush);
  }

  void _drawPixelHeart(Canvas canvas, Offset center, double size) {
    final heartPaint = Paint()
      ..color = const Color(0xFFFF1744)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.8);
    path.cubicTo(
      center.dx - size * 1.2, center.dy + size * 0.2,
      center.dx - size * 1.0, center.dy - size * 0.9,
      center.dx, center.dy - size * 0.3,
    );
    path.cubicTo(
      center.dx + size * 1.0, center.dy - size * 0.9,
      center.dx + size * 1.2, center.dy + size * 0.2,
      center.dx, center.dy + size * 0.8,
    );
    path.close();

    canvas.drawPath(path, heartPaint);
    canvas.drawPath(path, borderPaint);

    // Glint highlight
    final glintPaint = Paint()..color = Colors.white.withOpacity(0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx - size * 0.4, center.dy - size * 0.3), width: size * 0.3, height: size * 0.5),
      glintPaint,
    );
  }

  void _drawCosmicCat(Canvas canvas, Offset center, double w, double h) {
    final catPaint = Paint()
      ..color = const Color(0xFF7C4DFF)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Cat face circle
    canvas.drawCircle(center, w * 0.32, catPaint);
    canvas.drawCircle(center, w * 0.32, strokePaint);

    // Left Ear
    final leftEar = Path()
      ..moveTo(center.dx - w * 0.3, center.dy - h * 0.1)
      ..lineTo(center.dx - w * 0.35, center.dy - h * 0.35)
      ..lineTo(center.dx - w * 0.1, center.dy - h * 0.25)
      ..close();
    canvas.drawPath(leftEar, catPaint);
    canvas.drawPath(leftEar, strokePaint);

    // Right Ear
    final rightEar = Path()
      ..moveTo(center.dx + w * 0.3, center.dy - h * 0.1)
      ..lineTo(center.dx + w * 0.35, center.dy - h * 0.35)
      ..lineTo(center.dx + w * 0.1, center.dy - h * 0.25)
      ..close();
    canvas.drawPath(rightEar, catPaint);
    canvas.drawPath(rightEar, strokePaint);

    // Closed sleepy eyes (curved lines)
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final leftEye = Path()
      ..arcTo(Rect.fromCircle(center: Offset(center.dx - 12, center.dy), radius: 6), 0.2, math.pi - 0.4, true);
    final rightEye = Path()
      ..arcTo(Rect.fromCircle(center: Offset(center.dx + 12, center.dy), radius: 6), 0.2, math.pi - 0.4, true);
    canvas.drawPath(leftEye, eyePaint);
    canvas.drawPath(rightEye, eyePaint);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = const Color(0xFFB388FF)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(center.dx - 22, center.dy + 8), Offset(center.dx - 36, center.dy + 5), whiskerPaint);
    canvas.drawLine(Offset(center.dx - 22, center.dy + 12), Offset(center.dx - 36, center.dy + 15), whiskerPaint);
    canvas.drawLine(Offset(center.dx + 22, center.dy + 8), Offset(center.dx + 36, center.dy + 5), whiskerPaint);
    canvas.drawLine(Offset(center.dx + 22, center.dy + 12), Offset(center.dx + 36, center.dy + 15), whiskerPaint);
  }

  void _drawRetroTape(Canvas canvas, Offset center, double w, double h) {
    final bodyPaint = Paint()..color = const Color(0xFF263238);
    final accentPaint = Paint()..color = const Color(0xFFFF4081);
    final whitePaint = Paint()..color = Colors.white;

    final bodyRect = Rect.fromCenter(center: center, width: w * 0.8, height: h * 0.55);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(8)), bodyPaint);

    final labelRect = Rect.fromCenter(center: Offset(center.dx, center.dy - 5), width: w * 0.65, height: h * 0.25);
    canvas.drawRect(labelRect, accentPaint);

    // Reel holes
    canvas.drawCircle(Offset(center.dx - 18, center.dy + 5), 8, whitePaint);
    canvas.drawCircle(Offset(center.dx + 18, center.dy + 5), 8, whitePaint);
    canvas.drawCircle(Offset(center.dx - 18, center.dy + 5), 4, bodyPaint);
    canvas.drawCircle(Offset(center.dx + 18, center.dy + 5), 4, bodyPaint);
  }

  void _drawCyberSkull(Canvas canvas, Offset center, double w, double h) {
    final skullPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;

    final path = Path();
    path.addOval(Rect.fromCenter(center: Offset(center.dx, center.dy - 8), width: w * 0.55, height: h * 0.5));
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, skullPaint);

    // Teeth grid
    canvas.drawRect(Rect.fromCenter(center: Offset(center.dx, center.dy + 18), width: w * 0.3, height: h * 0.14), skullPaint);

    // Eyes
    canvas.drawCircle(Offset(center.dx - 10, center.dy - 8), 5, skullPaint);
    canvas.drawCircle(Offset(center.dx + 10, center.dy - 8), 5, skullPaint);
  }

  void _drawSunsetWave(Canvas canvas, Offset center, double radius) {
    // Circle container
    final circleRect = Rect.fromCircle(center: center, radius: radius);
    final clipPath = Path()..addOval(circleRect);
    canvas.save();
    canvas.clipPath(clipPath);

    // Sunset gradient sky
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF8A65), Color(0xFFFF4081), Color(0xFF7C4DFF)],
      ).createShader(circleRect);
    canvas.drawRect(circleRect, skyPaint);

    // Sun
    final sunPaint = Paint()..color = const Color(0xFFFFEE58);
    canvas.drawCircle(Offset(center.dx, center.dy - radius * 0.2), radius * 0.45, sunPaint);

    // Ocean waves
    final wavePaint = Paint()..color = const Color(0xFF1A237E);
    final wavePath = Path();
    wavePath.moveTo(center.dx - radius, center.dy + radius * 0.3);
    wavePath.quadraticBezierTo(center.dx - radius * 0.4, center.dy + radius * 0.1, center.dx, center.dy + radius * 0.3);
    wavePath.quadraticBezierTo(center.dx + radius * 0.4, center.dy + radius * 0.5, center.dx + radius, center.dy + radius * 0.3);
    wavePath.lineTo(center.dx + radius, center.dy + radius);
    wavePath.lineTo(center.dx - radius, center.dy + radius);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);

    canvas.restore();

    // Outline border
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, border);
  }

  void _drawMatchaLatte(Canvas canvas, Offset center, double w, double h) {
    final cupPaint = Paint()..color = const Color(0xFF66BB6A);
    final whitePaint = Paint()..color = Colors.white;
    final strokePaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Cup body
    final cupPath = Path();
    cupPath.moveTo(center.dx - w * 0.25, center.dy - h * 0.15);
    cupPath.lineTo(center.dx + w * 0.25, center.dy - h * 0.15);
    cupPath.lineTo(center.dx + w * 0.2, center.dy + h * 0.3);
    cupPath.lineTo(center.dx - w * 0.2, center.dy + h * 0.3);
    cupPath.close();

    canvas.drawPath(cupPath, cupPaint);
    canvas.drawPath(cupPath, strokePaint);

    // Foam top
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy - h * 0.15), width: w * 0.5, height: h * 0.15), whitePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy - h * 0.15), width: w * 0.5, height: h * 0.15), strokePaint);

    // Latte art heart
    final heart = Paint()..color = const Color(0xFF81C784);
    canvas.drawCircle(Offset(center.dx, center.dy - h * 0.15), 4, heart);
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF00E5FF), Color(0xFFE040FB)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      path.moveTo(center.dx, center.dy);
      path.quadraticBezierTo(
        center.dx + (radius * 0.2) * math.cos(angle + math.pi / 4),
        center.dy + (radius * 0.2) * math.sin(angle + math.pi / 4),
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      path.quadraticBezierTo(
        center.dx + (radius * 0.2) * math.cos(angle - math.pi / 4),
        center.dy + (radius * 0.2) * math.sin(angle - math.pi / 4),
        center.dx,
        center.dy,
      );
    }
    canvas.drawPath(path, paint);

    final whiteGlow = Paint()..color = Colors.white;
    canvas.drawCircle(center, 4, whiteGlow);
  }

  void _drawMushroom(Canvas canvas, Offset center, double w, double h) {
    final capPaint = Paint()..color = const Color(0xFFFF5252);
    final stemPaint = Paint()..color = const Color(0xFFFFF9C4);
    final strokePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Stem
    final stemRect = Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.15), width: w * 0.25, height: h * 0.3);
    canvas.drawRRect(RRect.fromRectAndRadius(stemRect, const Radius.circular(6)), stemPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(stemRect, const Radius.circular(6)), strokePaint);

    // Cap (dome)
    final capPath = Path();
    capPath.moveTo(center.dx - w * 0.35, center.dy + h * 0.05);
    capPath.arcToPoint(
      Offset(center.dx + w * 0.35, center.dy + h * 0.05),
      radius: Radius.circular(w * 0.35),
    );
    capPath.close();

    canvas.drawPath(capPath, capPaint);
    canvas.drawPath(capPath, strokePaint);

    // White polka dots
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(center.dx, center.dy - h * 0.1), 5, dotPaint);
    canvas.drawCircle(Offset(center.dx - w * 0.18, center.dy), 4, dotPaint);
    canvas.drawCircle(Offset(center.dx + w * 0.18, center.dy), 4, dotPaint);
  }

  void _drawLofiPlant(Canvas canvas, Offset center, double w, double h) {
    final potPaint = Paint()..color = const Color(0xFFFF8A65);
    final plantPaint = Paint()..color = const Color(0xFF4CAF50);
    final stroke = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Pot
    final potPath = Path();
    potPath.moveTo(center.dx - w * 0.22, center.dy + h * 0.05);
    potPath.lineTo(center.dx + w * 0.22, center.dy + h * 0.05);
    potPath.lineTo(center.dx + w * 0.16, center.dy + h * 0.35);
    potPath.lineTo(center.dx - w * 0.16, center.dy + h * 0.35);
    potPath.close();

    canvas.drawPath(potPath, potPaint);
    canvas.drawPath(potPath, stroke);

    // Leaves
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy - h * 0.15), width: w * 0.18, height: h * 0.35), plantPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - w * 0.15, center.dy - h * 0.05), width: w * 0.18, height: h * 0.25), plantPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + w * 0.15, center.dy - h * 0.05), width: w * 0.18, height: h * 0.25), plantPaint);
  }

  void _drawGameboy(Canvas canvas, Offset center, double w, double h) {
    final bodyPaint = Paint()..color = const Color(0xFF90A4AE);
    final screenPaint = Paint()..color = const Color(0xFF81C784);
    final buttonPaint = Paint()..color = const Color(0xFFE91E63);
    final dpadPaint = Paint()..color = const Color(0xFF263238);

    final bodyRect = Rect.fromCenter(center: center, width: w * 0.65, height: h * 0.8);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(12)), bodyPaint);

    final screenRect = Rect.fromCenter(center: Offset(center.dx, center.dy - h * 0.15), width: w * 0.45, height: h * 0.3);
    canvas.drawRRect(RRect.fromRectAndRadius(screenRect, const Radius.circular(6)), screenPaint);

    // D-pad
    canvas.drawRect(Rect.fromCenter(center: Offset(center.dx - 14, center.dy + h * 0.18), width: 14, height: 6), dpadPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(center.dx - 14, center.dy + h * 0.18), width: 6, height: 14), dpadPaint);

    // Buttons A/B
    canvas.drawCircle(Offset(center.dx + 12, center.dy + h * 0.2), 4, buttonPaint);
    canvas.drawCircle(Offset(center.dx + 22, center.dy + h * 0.15), 4, buttonPaint);
  }

  void _drawNeonCrystal(Canvas canvas, Offset center, double w, double h) {
    final crystalPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE040FB), Color(0xFF00E5FF)],
      ).createShader(Rect.fromCenter(center: center, width: w, height: h))
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(center.dx, center.dy - h * 0.35);
    path.lineTo(center.dx + w * 0.25, center.dy - h * 0.1);
    path.lineTo(center.dx, center.dy + h * 0.35);
    path.lineTo(center.dx - w * 0.25, center.dy - h * 0.1);
    path.close();

    canvas.drawPath(path, crystalPaint);
    canvas.drawPath(path, border);

    // Facet lines
    canvas.drawLine(Offset(center.dx, center.dy - h * 0.35), Offset(center.dx, center.dy + h * 0.35), border);
    canvas.drawLine(Offset(center.dx - w * 0.25, center.dy - h * 0.1), Offset(center.dx + w * 0.25, center.dy - h * 0.1), border);
  }

  @override
  bool shouldRepaint(covariant _VectorStickerPainter oldDelegate) =>
      oldDelegate.vectorId != vectorId;
}
