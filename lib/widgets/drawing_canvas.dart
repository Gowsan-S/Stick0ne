import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawnPoint {
  final Offset offset;
  final Paint paint;

  DrawnPoint({required this.offset, required this.paint});
}

class DrawingCanvas extends StatefulWidget {
  final Color selectedColor;
  final double strokeWidth;
  final bool isEraser;
  final GlobalKey repaintKey;
  final VoidCallback? onStrokeDrawn;

  const DrawingCanvas({
    super.key,
    required this.selectedColor,
    required this.strokeWidth,
    required this.isEraser,
    required this.repaintKey,
    this.onStrokeDrawn,
  });

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  final List<List<DrawnPoint>> _lines = [];

  void clear() {
    setState(() {
      _lines.clear();
    });
  }

  void undo() {
    if (_lines.isNotEmpty) {
      setState(() {
        _lines.removeLast();
      });
    }
  }

  bool get isEmpty => _lines.isEmpty;

  Future<Uint8List?> exportToPng() async {
    try {
      final boundary = widget.repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error exporting doodle to PNG: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.repaintKey,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: Colors.transparent,
          child: GestureDetector(
            onPanStart: (details) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox == null) return;
              final localPos = renderBox.globalToLocal(details.globalPosition);

              setState(() {
                final paint = Paint()
                  ..color = widget.isEraser ? Colors.transparent : widget.selectedColor
                  ..strokeWidth = widget.strokeWidth
                  ..strokeCap = StrokeCap.round
                  ..strokeJoin = StrokeJoin.round
                  ..blendMode = widget.isEraser ? BlendMode.clear : BlendMode.srcOver;

                _lines.add([DrawnPoint(offset: localPos, paint: paint)]);
              });
            },
            onPanUpdate: (details) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox == null || _lines.isEmpty) return;
              final localPos = renderBox.globalToLocal(details.globalPosition);

              setState(() {
                final paint = Paint()
                  ..color = widget.isEraser ? Colors.transparent : widget.selectedColor
                  ..strokeWidth = widget.strokeWidth
                  ..strokeCap = StrokeCap.round
                  ..strokeJoin = StrokeJoin.round
                  ..blendMode = widget.isEraser ? BlendMode.clear : BlendMode.srcOver;

                _lines.last.add(DrawnPoint(offset: localPos, paint: paint));
              });
            },
            onPanEnd: (details) {
              widget.onStrokeDrawn?.call();
            },
            child: CustomPaint(
              painter: _CanvasPainter(lines: _lines),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<List<DrawnPoint>> lines;

  _CanvasPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      if (line.isEmpty) continue;
      if (line.length == 1) {
        canvas.drawCircle(line[0].offset, line[0].paint.strokeWidth / 2, line[0].paint);
      } else {
        for (int i = 0; i < line.length - 1; i++) {
          canvas.drawLine(line[i].offset, line[i + 1].offset, line[i].paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
