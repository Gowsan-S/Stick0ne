import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CutMode { freehand, circle, rounded, rectangle }

class PhotoCutterScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const PhotoCutterScreen({
    super.key,
    required this.imageBytes,
  });

  @override
  State<PhotoCutterScreen> createState() => _PhotoCutterScreenState();
}

class _PhotoCutterScreenState extends State<PhotoCutterScreen> {
  ui.Image? _decodedImage;
  bool _isLoading = true;
  CutMode _cutMode = CutMode.freehand;

  // Freehand Lasso Points (in display coordinates)
  final List<Offset> _lassoPoints = [];
  bool _isLassoClosed = false;

  // Shape Cut Normalized Rect (relative to image display rect: 0.0 to 1.0)
  Rect _shapeNormRect = const Rect.fromLTWH(0.15, 0.15, 0.70, 0.70);

  // Dragging active handle or center
  int? _activeCorner; // 0: TL, 1: TR, 2: BR, 3: BL, 4: Center
  Offset? _lastPanPos;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetCut() {
    HapticFeedback.lightImpact();
    setState(() {
      _lassoPoints.clear();
      _isLassoClosed = false;
      _shapeNormRect = const Rect.fromLTWH(0.15, 0.15, 0.70, 0.70);
    });
  }

  Rect _calculateImageDestination(Size viewSize) {
    if (_decodedImage == null) return Rect.zero;
    final imgW = _decodedImage!.width.toDouble();
    final imgH = _decodedImage!.height.toDouble();
    final fitted = applyBoxFit(BoxFit.contain, Size(imgW, imgH), viewSize);
    return Alignment.center.inscribe(fitted.destination, Rect.fromLTWH(0, 0, viewSize.width, viewSize.height));
  }

  Future<void> _performCut(Rect destRect) async {
    if (_decodedImage == null) return;
    HapticFeedback.mediumImpact();

    final imgW = _decodedImage!.width.toDouble();
    final imgH = _decodedImage!.height.toDouble();

    final imagePath = Path();

    if (_cutMode == CutMode.freehand) {
      if (_lassoPoints.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF2C2C2E),
            content: Text('Please trace an outline around the object first.', style: TextStyle(color: Colors.white)),
          ),
        );
        return;
      }

      for (int i = 0; i < _lassoPoints.length; i++) {
        final pt = _lassoPoints[i];
        final imgX = (pt.dx - destRect.left) * (imgW / destRect.width);
        final imgY = (pt.dy - destRect.top) * (imgH / destRect.height);
        if (i == 0) {
          imagePath.moveTo(imgX, imgY);
        } else {
          imagePath.lineTo(imgX, imgY);
        }
      }
      imagePath.close();
    } else {
      final pixelLeft = _shapeNormRect.left * imgW;
      final pixelTop = _shapeNormRect.top * imgH;
      final pixelW = _shapeNormRect.width * imgW;
      final pixelH = _shapeNormRect.height * imgH;
      final rect = Rect.fromLTWH(pixelLeft, pixelTop, pixelW, pixelH);

      switch (_cutMode) {
        case CutMode.circle:
          imagePath.addOval(rect);
          break;
        case CutMode.rounded:
          imagePath.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide * 0.18)));
          break;
        case CutMode.rectangle:
          imagePath.addRect(rect);
          break;
        case CutMode.freehand:
          break;
      }
    }

    final bounds = imagePath.getBounds();
    final clampedBounds = bounds.intersect(Rect.fromLTWH(0, 0, imgW, imgH));

    if (clampedBounds.width < 5 || clampedBounds.height < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2C2C2E),
          content: Text('Selection is too small.', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, clampedBounds.width, clampedBounds.height));

      // Clip along the translated cut path
      final translatedPath = imagePath.shift(Offset(-clampedBounds.left, -clampedBounds.top));
      canvas.clipPath(translatedPath);

      // Draw the original image with offset
      canvas.drawImage(
        _decodedImage!,
        Offset(-clampedBounds.left, -clampedBounds.top),
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high,
      );

      final picture = recorder.endRecording();
      final cutImage = await picture.toImage(
        clampedBounds.width.round(),
        clampedBounds.height.round(),
      );

      final byteData = await cutImage.toByteData(format: ui.ImageByteFormat.png);
      final cutPngBytes = byteData?.buffer.asUint8List();

      if (mounted && cutPngBytes != null) {
        Navigator.pop(context, cutPngBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2C2C2E),
            content: Text('Failed to cut photo: $e', style: const TextStyle(color: Colors.white)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildModeSegmentedControl(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator(color: Colors.white, radius: 16))
                  : _decodedImage == null
                      ? const Center(child: Text('Failed to load image', style: TextStyle(color: Colors.white)))
                      : _buildCutterCanvas(),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cancel Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1C1E),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 18),
            ),
          ),

          // Title
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'CUT STICKER',
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Cut Photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          // Cut & Done Button
          Builder(
            builder: (ctx) {
              return ElevatedButton.icon(
                onPressed: () {
                  final renderBox = ctx.findAncestorRenderObjectOfType<RenderBox>();
                  final size = renderBox?.size ?? MediaQuery.of(context).size;
                  final destRect = _calculateImageDestination(Size(size.width, size.height - 220));
                  _performCut(destRect);
                },
                icon: const Icon(CupertinoIcons.scissors, color: Colors.black, size: 16),
                label: const Text(
                  'Cut',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeSegmentedControl() {
    final modes = [
      {'mode': CutMode.freehand, 'label': 'Lasso Cut', 'icon': CupertinoIcons.pencil_outline},
      {'mode': CutMode.circle, 'label': 'Circle', 'icon': CupertinoIcons.circle},
      {'mode': CutMode.rounded, 'label': 'Rounded', 'icon': CupertinoIcons.square},
      {'mode': CutMode.rectangle, 'label': 'Crop', 'icon': CupertinoIcons.crop},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
      ),
      child: Row(
        children: modes.map((m) {
          final mode = m['mode'] as CutMode;
          final label = m['label'] as String;
          final icon = m['icon'] as IconData;
          final isSelected = _cutMode == mode;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _cutMode = mode);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 13,
                      color: isSelected ? Colors.black : const Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.black : const Color(0xFF8E8E93),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCutterCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewSize = Size(constraints.maxWidth, constraints.maxHeight);
        final destRect = _calculateImageDestination(viewSize);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            final pos = details.localPosition;
            if (_cutMode == CutMode.freehand) {
              _lassoPoints.clear();
              _lassoPoints.add(pos);
              setState(() => _isLassoClosed = false);
            } else {
              _lastPanPos = pos;
              _activeCorner = _hitTestShapeHandle(pos, destRect);
            }
          },
          onPanUpdate: (details) {
            final pos = details.localPosition;
            if (_cutMode == CutMode.freehand) {
              setState(() {
                _lassoPoints.add(pos);
              });
            } else {
              if (_lastPanPos == null || _activeCorner == null) return;
              final delta = pos - _lastPanPos!;
              _lastPanPos = pos;
              _updateShapeNormRect(delta, destRect);
            }
          },
          onPanEnd: (details) {
            if (_cutMode == CutMode.freehand) {
              if (_lassoPoints.length > 2) {
                setState(() => _isLassoClosed = true);
              }
            } else {
              _activeCorner = null;
              _lastPanPos = null;
            }
          },
          child: CustomPaint(
            size: viewSize,
            painter: _PhotoCutterPainter(
              image: _decodedImage!,
              destRect: destRect,
              cutMode: _cutMode,
              lassoPoints: _lassoPoints,
              isLassoClosed: _isLassoClosed,
              shapeNormRect: _shapeNormRect,
            ),
          ),
        );
      },
    );
  }

  int? _hitTestShapeHandle(Offset pos, Rect destRect) {
    final shapePxRect = Rect.fromLTWH(
      destRect.left + _shapeNormRect.left * destRect.width,
      destRect.top + _shapeNormRect.top * destRect.height,
      _shapeNormRect.width * destRect.width,
      _shapeNormRect.height * destRect.height,
    );

    const handleRadius = 24.0;
    if ((pos - shapePxRect.topLeft).distance <= handleRadius) return 0; // TL
    if ((pos - shapePxRect.topRight).distance <= handleRadius) return 1; // TR
    if ((pos - shapePxRect.bottomRight).distance <= handleRadius) return 2; // BR
    if ((pos - shapePxRect.bottomLeft).distance <= handleRadius) return 3; // BL
    if (shapePxRect.contains(pos)) return 4; // Center move

    return null;
  }

  void _updateShapeNormRect(Offset delta, Rect destRect) {
    if (destRect.width <= 0 || destRect.height <= 0) return;
    final normDeltaX = delta.dx / destRect.width;
    final normDeltaY = delta.dy / destRect.height;

    double left = _shapeNormRect.left;
    double top = _shapeNormRect.top;
    double right = _shapeNormRect.right;
    double bottom = _shapeNormRect.bottom;

    if (_activeCorner == 4) {
      // Move entire crop box
      left = (left + normDeltaX).clamp(0.0, 1.0 - _shapeNormRect.width);
      top = (top + normDeltaY).clamp(0.0, 1.0 - _shapeNormRect.height);
      setState(() {
        _shapeNormRect = Rect.fromLTWH(left, top, _shapeNormRect.width, _shapeNormRect.height);
      });
      return;
    }

    // Resize corners
    if (_activeCorner == 0) { // TL
      left = (left + normDeltaX).clamp(0.0, right - 0.1);
      top = (top + normDeltaY).clamp(0.0, bottom - 0.1);
    } else if (_activeCorner == 1) { // TR
      right = (right + normDeltaX).clamp(left + 0.1, 1.0);
      top = (top + normDeltaY).clamp(0.0, bottom - 0.1);
    } else if (_activeCorner == 2) { // BR
      right = (right + normDeltaX).clamp(left + 0.1, 1.0);
      bottom = (bottom + normDeltaY).clamp(top + 0.1, 1.0);
    } else if (_activeCorner == 3) { // BL
      left = (left + normDeltaX).clamp(0.0, right - 0.1);
      bottom = (bottom + normDeltaY).clamp(top + 0.1, 1.0);
    }

    setState(() {
      _shapeNormRect = Rect.fromLTRB(left, top, right, bottom);
    });
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF141416),
        border: Border(top: BorderSide(color: Color(0x26FFFFFF), width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Reset / Clear path
          GestureDetector(
            onTap: _resetCut,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x33FFFFFF), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(CupertinoIcons.arrow_counterclockwise, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text('Reset Cut', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          // Instruction text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                _cutMode == CutMode.freehand
                    ? 'Trace an outline with your finger'
                    : 'Drag handles to size, drag inside to position',
                textAlign: TextAlign.end,
                maxLines: 2,
                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCutterPainter extends CustomPainter {
  final ui.Image image;
  final Rect destRect;
  final CutMode cutMode;
  final List<Offset> lassoPoints;
  final bool isLassoClosed;
  final Rect shapeNormRect;

  _PhotoCutterPainter({
    required this.image,
    required this.destRect,
    required this.cutMode,
    required this.lassoPoints,
    required this.isLassoClosed,
    required this.shapeNormRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (destRect.isEmpty) return;

    // 1. Draw original image within destRect
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(
      image,
      srcRect,
      destRect,
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium,
    );

    // 2. Build the cut Path
    final cutPath = Path();

    if (cutMode == CutMode.freehand) {
      if (lassoPoints.isNotEmpty) {
        cutPath.moveTo(lassoPoints.first.dx, lassoPoints.first.dy);
        for (int i = 1; i < lassoPoints.length; i++) {
          cutPath.lineTo(lassoPoints[i].dx, lassoPoints[i].dy);
        }
        if (isLassoClosed) {
          cutPath.close();
        }
      }
    } else {
      final pxRect = Rect.fromLTWH(
        destRect.left + shapeNormRect.left * destRect.width,
        destRect.top + shapeNormRect.top * destRect.height,
        shapeNormRect.width * destRect.width,
        shapeNormRect.height * destRect.height,
      );

      switch (cutMode) {
        case CutMode.circle:
          cutPath.addOval(pxRect);
          break;
        case CutMode.rounded:
          cutPath.addRRect(RRect.fromRectAndRadius(pxRect, Radius.circular(pxRect.shortestSide * 0.18)));
          break;
        case CutMode.rectangle:
          cutPath.addRect(pxRect);
          break;
        case CutMode.freehand:
          break;
      }
    }

    // 3. Dark Dimming Scrim outside cutPath
    final fullRectPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final scrimPath = Path.combine(PathOperation.difference, fullRectPath, cutPath);
    canvas.drawPath(scrimPath, Paint()..color = const Color(0xAA000000));

    // 4. White Glowing Border for cutPath
    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(cutPath, strokePaint);

    // 5. Draw Handles for Shape Mode
    if (cutMode != CutMode.freehand) {
      final pxRect = Rect.fromLTWH(
        destRect.left + shapeNormRect.left * destRect.width,
        destRect.top + shapeNormRect.top * destRect.height,
        shapeNormRect.width * destRect.width,
        shapeNormRect.height * destRect.height,
      );

      final handlePaint = Paint()..color = Colors.white;
      final handleBorderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final corners = [pxRect.topLeft, pxRect.topRight, pxRect.bottomRight, pxRect.bottomLeft];
      for (final corner in corners) {
        canvas.drawCircle(corner, 8.0, handlePaint);
        canvas.drawCircle(corner, 8.0, handleBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PhotoCutterPainter oldDelegate) => true;
}
