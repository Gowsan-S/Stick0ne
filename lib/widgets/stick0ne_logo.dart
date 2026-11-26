import 'package:flutter/material.dart';

/// Pixel-perfect vector widget rendering the official Stick0ne SVG logo.
class Stick0neLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final Color color;

  const Stick0neLogo({
    super.key,
    this.width,
    this.height = 24,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ?? 24.0;
    final w = width ?? (h * (775.0 / 78.0));

    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: _Stick0neLogoPainter(color: color),
      ),
    );
  }
}

class _Stick0neLogoPainter extends CustomPainter {
  final Color color;

  _Stick0neLogoPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.save();
    // Scale and translate viewBox "130 10 775 78" to fit size
    canvas.scale(size.width / 775.0, size.height / 78.0);
    canvas.translate(-130.0, -10.0);

    // --- S ---
    final pathS1 = Path()
      ..moveTo(164, 24.5)
      ..lineTo(226, 24.5)
      ..lineTo(220, 33.5)
      ..lineTo(151.5, 33.5)
      ..cubicTo(152.5, 27.5, 157, 24.5, 164, 24.5)
      ..close();
    canvas.drawPath(pathS1, paint);

    final pathS2 = Path()
      ..moveTo(162, 44.5)
      ..lineTo(217, 44.5)
      ..cubicTo(223.5, 44.5, 227.5, 48.5, 227.5, 55)
      ..lineTo(227.5, 63.5)
      ..cubicTo(227.5, 70, 223.5, 74, 217, 74)
      ..lineTo(150, 74)
      ..lineTo(156, 65)
      ..lineTo(216.5, 65)
      ..lineTo(216.5, 53.5)
      ..lineTo(156, 53.5)
      ..lineTo(150.5, 44.5)
      ..close();
    canvas.drawPath(pathS2, paint);

    // --- T ---
    final pathT = Path()
      ..moveTo(255, 24.5)
      ..lineTo(331.5, 24.5)
      ..lineTo(325.5, 33.5)
      ..lineTo(298.5, 33.5)
      ..lineTo(298.5, 74)
      ..lineTo(287.5, 74)
      ..lineTo(287.5, 33.5)
      ..lineTo(261, 33.5)
      ..close();
    canvas.drawPath(pathT, paint);

    // --- I ---
    canvas.drawRect(const Rect.fromLTWH(362, 24.5, 11, 49.5), paint);

    // --- C ---
    final pathC = Path()
      ..moveTo(417, 24.5)
      ..lineTo(474, 24.5)
      ..lineTo(468, 33.5)
      ..lineTo(417.5, 33.5)
      ..cubicTo(415.5, 33.5, 414.5, 34.5, 414.5, 36.5)
      ..lineTo(414.5, 62)
      ..cubicTo(414.5, 64, 415.5, 65, 417.5, 65)
      ..lineTo(468, 65)
      ..lineTo(474, 74)
      ..lineTo(417, 74)
      ..cubicTo(408, 74, 403.5, 69.5, 403.5, 60.5)
      ..lineTo(403.5, 38)
      ..cubicTo(403.5, 29, 408, 24.5, 417, 24.5)
      ..close();
    canvas.drawPath(pathC, paint);

    // --- K ---
    canvas.drawRect(const Rect.fromLTWH(506, 24.5, 11, 49.5), paint);
    final pathK = Path()
      ..moveTo(562, 24.5)
      ..lineTo(575.5, 24.5)
      ..lineTo(533.5, 49.25)
      ..lineTo(576.5, 74)
      ..lineTo(562.5, 74)
      ..lineTo(518.5, 49.25)
      ..close();
    canvas.drawPath(pathK, paint);

    // --- 0 (slashed zero - outer ring + inner cutout with evenodd) ---
    final pathO = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(621, 24)
      ..lineTo(664.5, 24)
      ..cubicTo(673.5, 24, 678.5, 29, 678.5, 38)
      ..lineTo(678.5, 60)
      ..cubicTo(678.5, 69, 673.5, 74, 664.5, 74)
      ..lineTo(621, 74)
      ..cubicTo(612, 74, 607, 69, 607, 60)
      ..lineTo(607, 38)
      ..cubicTo(607, 29, 612, 24, 621, 24)
      ..close()
      ..moveTo(620, 33)
      ..cubicTo(618.5, 33, 617.5, 34, 617.5, 35.5)
      ..lineTo(617.5, 62.5)
      ..cubicTo(617.5, 64, 618.5, 65, 620, 65)
      ..lineTo(665.5, 65)
      ..cubicTo(667, 65, 668, 64, 668, 62.5)
      ..lineTo(668, 35.5)
      ..cubicTo(668, 34, 667, 33, 665.5, 33)
      ..lineTo(620, 33)
      ..close();
    canvas.drawPath(pathO, paint);

    // 0 internal slash
    final pathSlash = Path()
      ..moveTo(617.5, 59.55)
      ..lineTo(659.4, 33)
      ..lineTo(668, 33)
      ..lineTo(668, 38.45)
      ..lineTo(626.1, 65)
      ..lineTo(617.5, 65)
      ..close();
    canvas.drawPath(pathSlash, paint);

    // --- N ---
    final pathN = Path()
      ..moveTo(711, 24.5)
      ..lineTo(721.5, 24.5)
      ..lineTo(771, 61.5)
      ..lineTo(771, 24.5)
      ..lineTo(781.5, 24.5)
      ..lineTo(781.5, 74)
      ..lineTo(771, 74)
      ..lineTo(721.5, 37)
      ..lineTo(721.5, 74)
      ..lineTo(711, 74)
      ..close();
    canvas.drawPath(pathN, paint);

    // --- E ---
    final pathE1 = Path()
      ..moveTo(813, 24.5)
      ..lineTo(885.5, 24.5)
      ..lineTo(879.5, 33.5)
      ..lineTo(819, 33.5)
      ..close();
    canvas.drawPath(pathE1, paint);

    final pathE2 = Path()
      ..moveTo(813, 44.75)
      ..lineTo(885.5, 44.75)
      ..lineTo(879.5, 53.75)
      ..lineTo(819, 53.75)
      ..close();
    canvas.drawPath(pathE2, paint);

    final pathE3 = Path()
      ..moveTo(813, 65)
      ..lineTo(885.5, 65)
      ..lineTo(879.5, 74)
      ..lineTo(819, 74)
      ..close();
    canvas.drawPath(pathE3, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Stick0neLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
