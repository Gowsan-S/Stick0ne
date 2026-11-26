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
      case 'barcode_tag':
        _drawBarcodeTag(canvas, center, w, h);
        break;
      case 'cyber_cross':
        _drawCyberCross(canvas, center, w, h);
        break;
      case 'y2k_planet':
        _drawPlanetRing(canvas, center, w, h);
        break;
      case 'digital_battery':
        _drawDigitalBattery(canvas, center, w, h);
        break;
      case 'acid_smile':
        _drawAcidSmile(canvas, center, w * 0.42);
        break;
      case 'sound_wave':
        _drawSoundWave(canvas, center, w, h);
        break;
      case 'status_pill':
        _drawStatusPill(canvas, center, w, h);
        break;
      case 'cyber_butterfly':
        _drawCyberButterfly(canvas, center, w, h);
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

  void _drawBarcodeTag(Canvas canvas, Offset center, double w, double h) {
    final tagRect = Rect.fromCenter(center: center, width: w * 0.88, height: h * 0.65);
    final tagRRect = RRect.fromRectAndRadius(tagRect, const Radius.circular(8));
    canvas.drawRRect(tagRRect, Paint()..color = const Color(0xF00A0A0C));
    canvas.drawRRect(tagRRect, Paint()..color = Colors.white..strokeWidth = 2.0..style = PaintingStyle.stroke);

    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'STICK0NE // OVERLAY',
        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(canvas, Offset(tagRect.left + 10, tagRect.top + 6));

    final barY = tagRect.top + 18;
    final barH = tagRect.height * 0.40;
    final barPaint = Paint()..color = Colors.white..strokeCap = StrokeCap.square;
    final barWidths = [2.0, 1.0, 3.5, 1.0, 2.0, 4.0, 1.5, 2.5, 1.0, 3.0, 1.5, 4.0, 2.0, 1.0, 3.0, 2.0, 1.5, 3.5, 1.0, 2.0];
    double currentX = tagRect.left + 10;
    for (final bw in barWidths) {
      barPaint.strokeWidth = bw;
      canvas.drawLine(Offset(currentX, barY), Offset(currentX, barY + barH), barPaint);
      currentX += bw + 2.2;
      if (currentX > tagRect.right - 10) break;
    }

    final codePainter = TextPainter(
      text: const TextSpan(
        text: 'NO. 2026-X89',
        style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 7, fontWeight: FontWeight.w600, letterSpacing: 1.2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    codePainter.paint(canvas, Offset(tagRect.left + 10, tagRect.bottom - 13));
  }

  void _drawCyberCross(Canvas canvas, Offset center, double w, double h) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final starPath = Path();
    final rOuter = w * 0.42;
    final rInner = w * 0.08;
    for (int i = 0; i < 8; i++) {
      final r = i.isEven ? rOuter : rInner;
      final angle = (i * math.pi / 4) - (math.pi / 2);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, paint);

    final holePath = Path();
    final rHole = w * 0.04;
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - (math.pi / 2);
      final x = center.dx + rHole * math.cos(angle);
      final y = center.dy + rHole * math.sin(angle);
      if (i == 0) {
        holePath.moveTo(x, y);
      } else {
        holePath.lineTo(x, y);
      }
    }
    holePath.close();
    canvas.drawPath(holePath, Paint()..color = Colors.black);

    final dotOffset = w * 0.30;
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(center.dx - dotOffset, center.dy - dotOffset), 2.5, dotPaint);
    canvas.drawCircle(Offset(center.dx + dotOffset, center.dy - dotOffset), 2.5, dotPaint);
    canvas.drawCircle(Offset(center.dx - dotOffset, center.dy + dotOffset), 2.5, dotPaint);
    canvas.drawCircle(Offset(center.dx + dotOffset, center.dy + dotOffset), 2.5, dotPaint);
  }

  void _drawPlanetRing(Canvas canvas, Offset center, double w, double h) {
    final sphereRadius = w * 0.24;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 6);
    final ringRect = Rect.fromCenter(center: Offset.zero, width: w * 0.88, height: h * 0.24);
    final ringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawOval(ringRect, ringPaint);
    canvas.restore();

    final spherePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(center, sphereRadius, spherePaint);

    final shadowPaint = Paint()..color = const Color(0xFF141416)..style = PaintingStyle.fill;
    final shadowPath = Path()
      ..addArc(Rect.fromCircle(center: center, radius: sphereRadius), -math.pi / 2, math.pi)
      ..arcTo(Rect.fromCenter(center: center, width: sphereRadius * 0.5, height: sphereRadius * 2), math.pi / 2, -math.pi, false);
    canvas.drawPath(shadowPath, shadowPaint);

    final linePaint = Paint()..color = Colors.white..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: center, radius: sphereRadius * 0.7), 0.2, 2.8, false, linePaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 6);
    canvas.drawArc(ringRect, 0, math.pi, false, ringPaint);
    canvas.restore();

    canvas.drawCircle(Offset(center.dx + w * 0.32, center.dy - h * 0.28), 2.0, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx - w * 0.34, center.dy + h * 0.26), 1.5, Paint()..color = Colors.white);
  }

  void _drawDigitalBattery(Canvas canvas, Offset center, double w, double h) {
    final bodyW = w * 0.72;
    final bodyH = h * 0.40;
    final bodyRect = Rect.fromCenter(center: Offset(center.dx - w * 0.03, center.dy), width: bodyW, height: bodyH);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(6));

    final borderPaint = Paint()..color = Colors.white..strokeWidth = 2.2..style = PaintingStyle.stroke;
    canvas.drawRRect(bodyRRect, borderPaint);

    final tipRect = Rect.fromLTWH(bodyRect.right, center.dy - 6, 4, 12);
    canvas.drawRRect(RRect.fromRectAndRadius(tipRect, const Radius.circular(2)), Paint()..color = Colors.white);

    const cellCount = 3;
    final cellGap = 3.0;
    final cellW = (bodyW - 12 - (cellGap * (cellCount - 1))) / cellCount;
    final cellPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    for (int i = 0; i < cellCount; i++) {
      final left = bodyRect.left + 6 + i * (cellW + cellGap);
      final cellRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, bodyRect.top + 5, cellW, bodyH - 10),
        const Radius.circular(3),
      );
      canvas.drawRRect(cellRRect, cellPaint);
    }
  }

  void _drawAcidSmile(Canvas canvas, Offset center, double radius) {
    final outlinePaint = Paint()..color = Colors.white..strokeWidth = 3.0..style = PaintingStyle.stroke;
    final fillPaint = Paint()..color = const Color(0xF00A0A0C)..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, outlinePaint);

    final eyePaint = Paint()..color = Colors.white..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    final eyeSize = radius * 0.25;

    final leftEyeCenter = Offset(center.dx - radius * 0.38, center.dy - radius * 0.2);
    canvas.drawLine(leftEyeCenter - Offset(eyeSize / 2, eyeSize / 2), leftEyeCenter + Offset(eyeSize / 2, eyeSize / 2), eyePaint);
    canvas.drawLine(leftEyeCenter - Offset(-eyeSize / 2, eyeSize / 2), leftEyeCenter + Offset(-eyeSize / 2, eyeSize / 2), eyePaint);

    final rightEyeCenter = Offset(center.dx + radius * 0.38, center.dy - radius * 0.2);
    canvas.drawLine(rightEyeCenter - Offset(eyeSize / 2, eyeSize / 2), rightEyeCenter + Offset(eyeSize / 2, eyeSize / 2), eyePaint);
    canvas.drawLine(rightEyeCenter - Offset(-eyeSize / 2, eyeSize / 2), rightEyeCenter + Offset(-eyeSize / 2, eyeSize / 2), eyePaint);

    final smilePath = Path()
      ..moveTo(center.dx - radius * 0.5, center.dy + radius * 0.15)
      ..quadraticBezierTo(center.dx, center.dy + radius * 0.65, center.dx + radius * 0.5, center.dy + radius * 0.15);
    canvas.drawPath(smilePath, outlinePaint..strokeCap = StrokeCap.round);
  }

  void _drawSoundWave(Canvas canvas, Offset center, double w, double h) {
    final wavePaint = Paint()..color = Colors.white..strokeCap = StrokeCap.round..strokeWidth = 3.5;
    final heights = [0.25, 0.55, 0.90, 0.45, 1.0, 0.70, 0.85, 0.40, 0.20];
    final barSpacing = (w * 0.75) / (heights.length - 1);
    final startX = center.dx - (w * 0.75) / 2;
    final maxH = h * 0.5;
    for (int i = 0; i < heights.length; i++) {
      final x = startX + i * barSpacing;
      final barHeight = maxH * heights[i];
      canvas.drawLine(Offset(x, center.dy - barHeight / 2), Offset(x, center.dy + barHeight / 2), wavePaint);
    }
  }

  void _drawStatusPill(Canvas canvas, Offset center, double w, double h) {
    final pillRect = Rect.fromCenter(center: center, width: w * 0.88, height: h * 0.38);
    final pillRRect = RRect.fromRectAndRadius(pillRect, Radius.circular(pillRect.height / 2));
    canvas.drawRRect(pillRRect, Paint()..color = const Color(0xE60A0A0C));
    canvas.drawRRect(pillRRect, Paint()..color = Colors.white..strokeWidth = 1.8..style = PaintingStyle.stroke);

    final dotCenter = Offset(pillRect.left + 14, center.dy);
    canvas.drawCircle(dotCenter, 3.5, Paint()..color = const Color(0xFF30D158));
    canvas.drawCircle(dotCenter, 5.5, Paint()..color = const Color(0x4030D158));

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'SYS ACTIVE',
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(dotCenter.dx + 8, center.dy - textPainter.height / 2));
  }

  void _drawCyberButterfly(Canvas canvas, Offset center, double w, double h) {
    final wingPaint = Paint()..color = Colors.white..strokeWidth = 1.8..style = PaintingStyle.stroke;
    final fillPaint = Paint()..color = const Color(0x33FFFFFF)..style = PaintingStyle.fill;

    final lTop = Path()
      ..moveTo(center.dx, center.dy - 4)
      ..lineTo(center.dx - w * 0.38, center.dy - h * 0.35)
      ..lineTo(center.dx - w * 0.42, center.dy - h * 0.1)
      ..lineTo(center.dx - w * 0.15, center.dy + 4)
      ..close();
    canvas.drawPath(lTop, fillPaint);
    canvas.drawPath(lTop, wingPaint);

    final rTop = Path()
      ..moveTo(center.dx, center.dy - 4)
      ..lineTo(center.dx + w * 0.38, center.dy - h * 0.35)
      ..lineTo(center.dx + w * 0.42, center.dy - h * 0.1)
      ..lineTo(center.dx + w * 0.15, center.dy + 4)
      ..close();
    canvas.drawPath(rTop, fillPaint);
    canvas.drawPath(rTop, wingPaint);

    final lBot = Path()
      ..moveTo(center.dx, center.dy + 4)
      ..lineTo(center.dx - w * 0.28, center.dy + h * 0.32)
      ..lineTo(center.dx - w * 0.1, center.dy + h * 0.28)
      ..close();
    canvas.drawPath(lBot, fillPaint);
    canvas.drawPath(lBot, wingPaint);

    final rBot = Path()
      ..moveTo(center.dx, center.dy + 4)
      ..lineTo(center.dx + w * 0.28, center.dy + h * 0.32)
      ..lineTo(center.dx + w * 0.1, center.dy + h * 0.28)
      ..close();
    canvas.drawPath(rBot, fillPaint);
    canvas.drawPath(rBot, wingPaint);

    final bodyPaint = Paint()..color = Colors.white..strokeWidth = 2.0..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx, center.dy - h * 0.18), Offset(center.dx, center.dy + h * 0.22), bodyPaint);
    canvas.drawLine(Offset(center.dx, center.dy - h * 0.18), Offset(center.dx - 6, center.dy - h * 0.28), bodyPaint..strokeWidth = 1.2);
    canvas.drawLine(Offset(center.dx, center.dy - h * 0.18), Offset(center.dx + 6, center.dy - h * 0.28), bodyPaint..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant _VectorStickerPainter oldDelegate) =>
      oldDelegate.vectorId != vectorId;
}
