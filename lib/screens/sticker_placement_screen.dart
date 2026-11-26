import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/sticker_placement.dart';
import '../providers/canvas_provider.dart';
import '../providers/sticker_provider.dart';
import '../widgets/vector_stickers.dart';
import '../widgets/stick0ne_logo.dart';

class StickerPlacementScreen extends StatefulWidget {
  final VoidCallback onNavigateToSearch;

  const StickerPlacementScreen({
    super.key,
    required this.onNavigateToSearch,
  });

  @override
  State<StickerPlacementScreen> createState() => _StickerPlacementScreenState();
}

class _StickerPlacementScreenState extends State<StickerPlacementScreen> {
  final GlobalKey _canvasRepaintKey = GlobalKey();
  final GlobalKey _stickersRepaintKey = GlobalKey();
  bool _isExporting = false;

  // Multi-touch tracking for canvas-wide 2-finger gesture (minimise, maximise, rotate)
  final Map<int, Offset> _canvasPointers = {};
  String? _gesturePlacementId;
  int? _photoPointerId;
  int? _screenPointerId;
  Offset? _initialPhotoPos;
  double? _initialDistance;
  double? _initialAngle;
  double? _initialScale;
  double? _initialRotation;
  Offset? _initialCenter;

  // Active transforms for 120 FPS hardware performance
  double? _activeX;
  double? _activeY;
  double? _activeScale;
  double? _activeRotation;

  void _showAddStickerSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final stickerProvider = context.read<StickerProvider>();
    final canvasProvider = context.read<CanvasProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: BoxDecoration(
                color: const Color(0xF01C1C1E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF48484A),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Sticker',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(CupertinoIcons.xmark_circle_fill,
                              color: Color(0xFF8E8E93), size: 24),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: stickerProvider.stickers.length,
                      itemBuilder: (context, index) {
                        final sticker = stickerProvider.stickers[index];
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            canvasProvider.addSticker(sticker);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
                            ),
                            child: Center(
                              child: StickerDisplayWidget(
                                sticker: sticker,
                                size: 48,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _renderAndDisplayScreen() async {
    final canvasProvider = context.read<CanvasProvider>();
    if (canvasProvider.placements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2C2C2E),
          content: const Text('Add at least one sticker to the canvas first!',
              style: TextStyle(color: Colors.white)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    setState(() => _isExporting = true);

    try {
      final prevSelected = canvasProvider.selectedPlacementId;
      canvasProvider.selectPlacement(null);

      // Allow frame to rebuild cleanly with isExporting=true and no selection handles
      await Future.delayed(const Duration(milliseconds: 80));

      final fullBoundary = _canvasRepaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (fullBoundary == null) {
        throw Exception('Canvas render boundary not found');
      }
      final fullImage = await fullBoundary.toImage(pixelRatio: devicePixelRatio);
      final fullByteData = await fullImage.toByteData(format: ui.ImageByteFormat.png);

      final stickersBoundary = _stickersRepaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      Uint8List? transparentBytes;
      if (stickersBoundary != null) {
        final transparentImage = await stickersBoundary.toImage(pixelRatio: devicePixelRatio);
        final transByteData =
            await transparentImage.toByteData(format: ui.ImageByteFormat.png);
        transparentBytes = transByteData?.buffer.asUint8List();
      }

      if (prevSelected != null && mounted) {
        canvasProvider.selectPlacement(prevSelected);
      }

      if (fullByteData == null) {
        throw Exception('Failed to generate image bytes');
      }

      final fullBytes = fullByteData.buffer.asUint8List();

      if (!mounted) return;

      final transparent = transparentBytes ?? fullBytes;
      final result = await canvasProvider.stickToScreen(transparent);

      if (!mounted) return;

      if (result.permissionNeeded) {
        _showPermissionDialog();
        return;
      }

      if (result.success) {
        await canvasProvider.saveCurrentDesign(thumbnailBytes: fullBytes);
        HapticFeedback.heavyImpact();
      }

      final isXiaomi = await canvasProvider.isXiaomiDevice();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1C1C1E),
          content: Text(
            result.success
                ? 'Stickers stuck on your screen!'
                : result.message,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          action: (result.success && isXiaomi)
              ? SnackBarAction(
                  label: 'Xiaomi Setup',
                  textColor: const Color(0xFFFF9F0A),
                  onPressed: () => canvasProvider.openMiuiPermissionSettings(),
                )
              : null,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2C2C2E),
            content: Text('Failed to render: $e',
                style: const TextStyle(color: Colors.white)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showPermissionDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'To keep stickers visible on screen floating over your apps and launcher, please enable "Appear on top" in system settings.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Open Settings'),
            onPressed: () async {
              Navigator.pop(ctx);
              final canvas = context.read<CanvasProvider>();
              await canvas.requestOverlayPermission();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateScreenDirectly() async {
    final canvasProvider = context.read<CanvasProvider>();
    if (canvasProvider.placements.isEmpty) {
      await _removeFromScreenDirectly();
      return;
    }

    HapticFeedback.heavyImpact();
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    setState(() => _isExporting = true);

    try {
      final prevSelected = canvasProvider.selectedPlacementId;
      canvasProvider.selectPlacement(null);

      // Allow frame to rebuild cleanly with isExporting=true and no selection handles
      await Future.delayed(const Duration(milliseconds: 80));

      final stickersBoundary = _stickersRepaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (stickersBoundary == null) {
        throw Exception('Canvas render boundary not found');
      }

      final transparentImage = await stickersBoundary.toImage(pixelRatio: devicePixelRatio);
      final transByteData =
          await transparentImage.toByteData(format: ui.ImageByteFormat.png);
      final transparentBytes = transByteData?.buffer.asUint8List();

      if (prevSelected != null && mounted) {
        canvasProvider.selectPlacement(prevSelected);
      }

      if (transparentBytes == null) {
        throw Exception('Failed to generate image bytes');
      }

      final result = await canvasProvider.stickToScreen(transparentBytes);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1C1C1E),
          content: Text(
            result.success
                ? 'Stickers updated on your screen!'
                : result.message,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2C2C2E),
          content: Text('Failed to update screen: $e',
              style: const TextStyle(color: Colors.white)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _removeFromScreenDirectly() async {
    HapticFeedback.mediumImpact();
    final canvasProvider = context.read<CanvasProvider>();
    final success = await canvasProvider.removeFromScreen();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1C1C1E),
        content: Text(
          success
              ? 'Stickers removed from screen.'
              : 'Failed to remove stickers.',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteSinglePlacement(String id) async {
    HapticFeedback.mediumImpact();
    final canvas = context.read<CanvasProvider>();
    canvas.setIsGesturing(false);
    setState(() {
      _gesturePlacementId = null;
      _photoPointerId = null;
      _screenPointerId = null;
      _activeX = null;
      _activeY = null;
      _activeScale = null;
      _activeRotation = null;
    });
    canvas.removePlacement(id);

    // If overlay is live on phone screen, immediately update the screen display
    if (canvas.isOverlayActive) {
      if (canvas.placements.isEmpty) {
        await _removeFromScreenDirectly();
      } else {
        await _updateScreenDirectly();
      }
    }
  }

  void _clearCanvasConfirm() {
    final canvasProvider = context.read<CanvasProvider>();
    final count = canvasProvider.placements.length;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(count > 1 ? 'Clear All $count Stickers?' : 'Clear Canvas & Screen?'),
        content: const Text(
          'This will remove all stickers from both your canvas and the phone screen.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _gesturePlacementId = null;
                _photoPointerId = null;
                _screenPointerId = null;
                _activeX = null;
                _activeY = null;
                _activeScale = null;
                _activeRotation = null;
              });
              await canvasProvider.removeFromScreen();
              await canvasProvider.resetCanvas();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF1C1C1E),
                    content: const Text(
                      'All stickers cleared from canvas and screen.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  // --- TWO-FINGER CANVAS GESTURE ENGINE (MINIMISE, MAXIMISE, ROTATE) ---

  bool _isPointInsideStickerBox(
    Offset point,
    double centerX,
    double centerY,
    double scale,
    double rotation,
  ) {
    final size = 100.0 * scale;
    // 24px comfortable finger touch margin
    final halfW = (size / 2) + 24;
    final halfH = (size / 2) + 24;

    final dx = point.dx - centerX;
    final dy = point.dy - centerY;

    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);

    final localX = dx * cosR + dy * sinR;
    final localY = -dx * sinR + dy * cosR;

    return localX.abs() <= halfW && localY.abs() <= halfH;
  }

  void _handleCanvasPointerDown(
    PointerDownEvent event,
    CanvasProvider canvas,
    double canvasWidth,
    double canvasHeight,
  ) {
    if (_isExporting) return;
    _canvasPointers[event.pointer] = event.localPosition;

    // Check if touch hits any sticker (topmost first)
    String? hitStickerId;
    for (final placement in canvas.placements.reversed) {
      final scale = (_gesturePlacementId == placement.id ? _activeScale : null) ?? placement.scale;
      final rotation = (_gesturePlacementId == placement.id ? _activeRotation : null) ?? placement.rotation;
      final posX = (_gesturePlacementId == placement.id ? _activeX : null) ?? (placement.x * canvasWidth);
      final posY = (_gesturePlacementId == placement.id ? _activeY : null) ?? (placement.y * canvasHeight);

      if (_isPointInsideStickerBox(event.localPosition, posX, posY, scale, rotation)) {
        hitStickerId = placement.id;
        break;
      }
    }

    if (hitStickerId != null) {
      if (_gesturePlacementId == null || _gesturePlacementId != hitStickerId) {
        // First finger touched down on this sticker
        _gesturePlacementId = hitStickerId;
        canvas.setIsGesturing(true);
        canvas.bringPlacementToFront(hitStickerId);
        canvas.selectPlacement(hitStickerId);
        HapticFeedback.selectionClick();

        final placement = canvas.placements.firstWhere((p) => p.id == hitStickerId);
        _photoPointerId = event.pointer;
        _initialPhotoPos = event.localPosition;
        _initialCenter = Offset(placement.x * canvasWidth, placement.y * canvasHeight);
        _initialScale = placement.scale;
        _initialRotation = placement.rotation;

        _activeX = _initialCenter!.dx;
        _activeY = _initialCenter!.dy;
        _activeScale = _initialScale;
        _activeRotation = _initialRotation;
      } else {
        // Second finger touched down on the photo
        if (_photoPointerId != null && _screenPointerId == null && event.pointer != _photoPointerId) {
          _screenPointerId = event.pointer;
          _initTwoFingerGesture();
        }
      }
    } else {
      // Finger touched anywhere outside stickers on the screen
      if (_gesturePlacementId != null && _photoPointerId != null && _screenPointerId == null) {
        // One finger on photo, other finger anywhere on screen -> engage minimise, maximise, rotate!
        _screenPointerId = event.pointer;
        _initTwoFingerGesture();
      }
    }
  }

  void _initTwoFingerGesture() {
    if (_photoPointerId == null || _screenPointerId == null) return;
    final pPhoto = _canvasPointers[_photoPointerId];
    final pScreen = _canvasPointers[_screenPointerId];
    if (pPhoto == null || pScreen == null) return;

    HapticFeedback.lightImpact();
    _initialDistance = (pScreen - pPhoto).distance;
    _initialAngle = math.atan2(pScreen.dy - pPhoto.dy, pScreen.dx - pPhoto.dx);
    _initialScale = _activeScale ?? 1.0;
    _initialRotation = _activeRotation ?? 0.0;
    _initialPhotoPos = pPhoto;
    _initialCenter = Offset(_activeX ?? 0, _activeY ?? 0);
  }

  void _handleCanvasPointerMove(
    PointerMoveEvent event,
    CanvasProvider canvas,
    double canvasWidth,
    double canvasHeight,
  ) {
    if (_isExporting || _gesturePlacementId == null) return;
    _canvasPointers[event.pointer] = event.localPosition;

    if (_photoPointerId != null && _screenPointerId != null) {
      // TWO FINGERS: Minimising (closer), Maximising (away), Rotating (clockwise/anticlockwise)
      final pPhoto = _canvasPointers[_photoPointerId];
      final pScreen = _canvasPointers[_screenPointerId];
      if (pPhoto == null || pScreen == null) return;

      if (_initialDistance != null && _initialDistance! > 10) {
        final currentDistance = (pScreen - pPhoto).distance;
        final currentAngle = math.atan2(pScreen.dy - pPhoto.dy, pScreen.dx - pPhoto.dx);

        // 1 & 2: Minimising (closer) & Maximising (away)
        final scaleRatio = currentDistance / _initialDistance!;
        final newScale = (_initialScale! * scaleRatio).clamp(0.2, 4.0);

        // 3: Rotating clockwise or anticlockwise
        double angleDelta = currentAngle - _initialAngle!;
        while (angleDelta > math.pi) {
          angleDelta -= 2 * math.pi;
        }
        while (angleDelta < -math.pi) {
          angleDelta += 2 * math.pi;
        }
        final newRotation = _initialRotation! + angleDelta;

        // Photo follows finger 1
        final photoDelta = pPhoto - _initialPhotoPos!;
        final newCenterX = _initialCenter!.dx + photoDelta.dx;
        final newCenterY = _initialCenter!.dy + photoDelta.dy;

        setState(() {
          _activeScale = newScale;
          _activeRotation = newRotation;
          _activeX = newCenterX;
          _activeY = newCenterY;
        });
      }
    } else if (_photoPointerId != null && _screenPointerId == null) {
      // ONE FINGER on photo: Smooth dragging across canvas
      final pPhoto = _canvasPointers[_photoPointerId];
      if (pPhoto != null && _initialPhotoPos != null && _initialCenter != null) {
        final photoDelta = pPhoto - _initialPhotoPos!;
        setState(() {
          _activeX = _initialCenter!.dx + photoDelta.dx;
          _activeY = _initialCenter!.dy + photoDelta.dy;
        });
      }
    }
  }

  void _handleCanvasPointerUp(
    PointerUpEvent event,
    CanvasProvider canvas,
    double canvasWidth,
    double canvasHeight,
  ) {
    if (_isExporting) return;
    _canvasPointers.remove(event.pointer);

    if (event.pointer == _screenPointerId) {
      _screenPointerId = null;
      _initialDistance = null;
      _initialAngle = null;
      if (_photoPointerId != null && _canvasPointers.containsKey(_photoPointerId)) {
        _initialPhotoPos = _canvasPointers[_photoPointerId];
        _initialCenter = Offset(_activeX ?? 0, _activeY ?? 0);
        _initialScale = _activeScale;
        _initialRotation = _activeRotation;
      }
    } else if (event.pointer == _photoPointerId) {
      _photoPointerId = null;
      _screenPointerId = null;
    }

    if (_photoPointerId == null && _screenPointerId == null && _gesturePlacementId != null) {
      _commitPlacementChanges(canvas, canvasWidth, canvasHeight);
    }
  }

  void _handleCanvasPointerCancel(
    PointerCancelEvent event,
    CanvasProvider canvas,
    double canvasWidth,
    double canvasHeight,
  ) {
    _handleCanvasPointerUp(
      PointerUpEvent(pointer: event.pointer, position: event.position),
      canvas,
      canvasWidth,
      canvasHeight,
    );
  }

  void _commitPlacementChanges(CanvasProvider canvas, double canvasWidth, double canvasHeight) {
    if (_gesturePlacementId == null) return;
    final id = _gesturePlacementId!;

    if (_activeX != null && _activeY != null) {
      final normX = _activeX! / canvasWidth;
      final normY = _activeY! / canvasHeight;
      canvas.updatePlacementPosition(id, normX, normY);
    }
    if (_activeScale != null) {
      canvas.updatePlacementScale(id, _activeScale!);
    }
    if (_activeRotation != null) {
      canvas.updatePlacementRotation(id, _activeRotation!);
    }

    canvas.setIsGesturing(false);
    setState(() {
      _gesturePlacementId = null;
      _photoPointerId = null;
      _screenPointerId = null;
      _initialDistance = null;
      _initialAngle = null;
      _activeX = null;
      _activeY = null;
      _activeScale = null;
      _activeRotation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canvas = context.watch<CanvasProvider>();
    final activePlacement = canvas.selectedPlacement ??
        (canvas.placements.isNotEmpty ? canvas.placements.last : null);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FULL-SCREEN BLANK CANVAS (Matches physical phone screen 1:1)
          Positioned.fill(
            child: _buildBlankScreenCanvas(canvas),
          ),

          // 2. MINIMALIST FLOATING TOP BAR (Padded by SafeArea)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _buildIosTopBar(canvas),
            ),
          ),

          // 3. TRANSPARENCY & EDIT/DELETE PANEL BELOW (Floating cleanly above bottom tab bar)
          if (activePlacement != null)
            Positioned(
              bottom: 88, // elevated safely above 64px tab bar + padding
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _gesturePlacementId != null ? 0.18 : 1.0,
                child: _buildTransparencyBottomPanel(canvas, activePlacement),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIosTopBar(CanvasProvider canvas) {
    final isOverlayActive = canvas.isOverlayActive;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xE6000000),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          if (canvas.placements.isNotEmpty) ...[
            GestureDetector(
              onTap: _clearCanvasConfirm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x33FF453A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x66FF453A), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.trash, color: Color(0xFFFF453A), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      canvas.placements.length > 1
                          ? 'Clear All (${canvas.placements.length})'
                          : 'Clear',
                      style: const TextStyle(
                        color: Color(0xFFFF453A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: canvas.placements.isEmpty
                      ? const Stick0neLogo(height: 15, color: Color(0xFFE5E5EA))
                      : Text(
                          canvas.currentDesignName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                ),
                if (isOverlayActive) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0x3330D158),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF30D158), width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.pin_fill, color: Color(0xFF30D158), size: 9),
                        SizedBox(width: 3),
                        Text(
                          'ON SCREEN',
                          style: TextStyle(
                            color: Color(0xFF30D158),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: () => _showAddStickerSheet(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1C1E),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.plus, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlankScreenCanvas(CanvasProvider canvas) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = constraints.maxWidth;
        final canvasHeight = constraints.maxHeight;

        return RepaintBoundary(
          key: _canvasRepaintKey,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) =>
                _handleCanvasPointerDown(event, canvas, canvasWidth, canvasHeight),
            onPointerMove: (event) =>
                _handleCanvasPointerMove(event, canvas, canvasWidth, canvasHeight),
            onPointerUp: (event) =>
                _handleCanvasPointerUp(event, canvas, canvasWidth, canvasHeight),
            onPointerCancel: (event) =>
                _handleCanvasPointerCancel(event, canvas, canvasWidth, canvasHeight),
            child: Container(
              width: canvasWidth,
              height: canvasHeight,
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none, // Allows sticker to go after the end of screen
                children: [
                  // Isolated stickers boundary for 100% transparent overlay export
                  RepaintBoundary(
                    key: _stickersRepaintKey,
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none, // Allows sticker to go after the end of screen
                      children: [
                        ...canvas.placements.map((placement) {
                          final isBeingGestured = _gesturePlacementId == placement.id;
                          return _DraggableStickerWidget(
                            key: ValueKey(placement.id),
                            placement: placement,
                            canvasWidth: canvasWidth,
                            canvasHeight: canvasHeight,
                            isSelected: canvas.selectedPlacementId == placement.id,
                            isExporting: _isExporting,
                            activeScale: isBeingGestured ? _activeScale : null,
                            activeRotation: isBeingGestured ? _activeRotation : null,
                            activePixelX: isBeingGestured ? _activeX : null,
                            activePixelY: isBeingGestured ? _activeY : null,
                            onSelect: () {
                              canvas.bringPlacementToFront(placement.id);
                              canvas.selectPlacement(placement.id);
                            },
                            onDelete: () => _deleteSinglePlacement(placement.id),
                          );
                        }),
                      ],
                    ),
                  ),

                  if (canvas.placements.isEmpty)
                    Center(
                      child: GestureDetector(
                        onTap: () => _showAddStickerSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xCC1C1C1E),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0x33FFFFFF), width: 0.8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(CupertinoIcons.plus_circle, color: Colors.white, size: 38),
                              SizedBox(height: 12),
                              Text(
                                'Blank Canvas',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tap to add your sticker',
                                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransparencyBottomPanel(
    CanvasProvider canvas,
    StickerPlacement activePlacement,
  ) {
    final isOverlayActive = canvas.isOverlayActive;
    final isGesturing = _gesturePlacementId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: isGesturing ? 4 : 16,
            sigmaY: isGesturing ? 4 : 16,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x3DFFFFFF), // Crystalline specular highlight
                  Color(0x14FFFFFF), // Fluid transparent optical glass body
                  Color(0x08FFFFFF), // Clean transparent bottom
                ],
                stops: [0.0, 0.45, 1.0],
              ),
              border: Border.all(
                color: const Color(0x66FFFFFF), // 40% white crystalline specular rim
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Glass Specular Reflection Highlight Line
                Container(
                  height: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0x4DFFFFFF),
                        Color(0x99FFFFFF),
                        Color(0x4DFFFFFF),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),

                // 1. Transparency Slider Row
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.circle_righthalf_fill,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Transparency',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: activePlacement.opacity.clamp(0.05, 1.0),
                        min: 0.05,
                        max: 1.0,
                        activeColor: Colors.white,
                        inactiveColor: const Color(0x33FFFFFF), // Translucent frosted track
                        onChanged: (val) {
                          canvas.updatePlacementOpacity(activePlacement.id, val);
                        },
                      ),
                    ),
                    Container(
                      width: 48,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${(activePlacement.opacity * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 2. Action Controls Row: Delete / Add / Remove Screen / Update Screen / Stick to Screen
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Delete Selected Sticker Button
                      GestureDetector(
                        onTap: () => _deleteSinglePlacement(activePlacement.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0x33FF453A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x66FF453A), width: 0.9),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.trash, color: Color(0xFFFF453A), size: 13),
                              SizedBox(width: 4),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Color(0xFFFF453A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 5),

                      // Quick Add button to place N stickers
                      GestureDetector(
                        onTap: () => _showAddStickerSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0x29FFFFFF), // Liquid frosted pill
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x40FFFFFF), width: 0.9),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.plus, color: Colors.white, size: 13),
                              SizedBox(width: 4),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 5),

                      // If stuck on screen: Show "Remove Screen" + "Update Screen" (Feature 4 Edit/Delete after sticked)
                      if (isOverlayActive) ...[
                        GestureDetector(
                          onTap: _removeFromScreenDirectly,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0x29FFFFFF), // Liquid frosted pill
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0x40FFFFFF), width: 0.9),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.clear_circled, color: Color(0xFFE5E5EA), size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: Color(0xFFE5E5EA),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        ElevatedButton.icon(
                          onPressed: _isExporting ? null : _updateScreenDirectly,
                          icon: const Icon(CupertinoIcons.arrow_2_circlepath, color: Colors.black, size: 13),
                          label: const Text(
                            'Update',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xF2FFFFFF),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ] else ...[
                        // If not stuck on screen: "Stick to Screen" primary button
                        ElevatedButton.icon(
                          onPressed: _isExporting ? null : _renderAndDisplayScreen,
                          icon: const Icon(CupertinoIcons.pin_fill, color: Colors.black, size: 13),
                          label: const Text(
                            'Stick to Screen',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xF2FFFFFF),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dedicated high-performance Rotatable & Scalable Sticker widget with pure gesture support
class _DraggableStickerWidget extends StatelessWidget {
  final StickerPlacement placement;
  final double canvasWidth;
  final double canvasHeight;
  final bool isSelected;
  final bool isExporting;
  final double? activeScale;
  final double? activeRotation;
  final double? activePixelX;
  final double? activePixelY;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _DraggableStickerWidget({
    super.key,
    required this.placement,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.isSelected,
    this.isExporting = false,
    this.activeScale,
    this.activeRotation,
    this.activePixelX,
    this.activePixelY,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scale = activeScale ?? placement.scale;
    final rotation = activeRotation ?? placement.rotation;
    final baseSize = 100.0 * scale;

    final posX = activePixelX ?? (placement.x * canvasWidth);
    final posY = activePixelY ?? (placement.y * canvasHeight);

    // Suppress all editing handles, badges, and borders when exporting or unselected
    final showEditingControls = isSelected && !isExporting;
    final degrees = (rotation * 180 / math.pi).round() % 360;

    return Positioned(
      left: posX - (baseSize / 2),
      top: posY - (baseSize / 2),
      child: Transform.rotate(
        angle: rotation,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Sticker Graphic
            Opacity(
              opacity: placement.opacity.clamp(0.05, 1.0),
              child: Container(
                width: baseSize,
                height: baseSize,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: showEditingControls
                      ? Border.all(color: Colors.white, width: 1.5)
                      : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: StickerDisplayWidget(
                    sticker: placement.sticker,
                    size: baseSize - 8,
                  ),
                ),
              ),
            ),

            // 2. Selection Indicators & Actions (Rotates with sticker)
            if (showEditingControls) ...[
              // Floating Live Size & Angle Indicator Badge
              Positioned(
                top: -34,
                left: -30,
                right: -30,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xE61C1C1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x66FFFFFF), width: 0.8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.rotate_right, color: Colors.white, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          '${(scale * 100).round()}%${degrees != 0 ? ' • $degrees°' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Top-Right Corner Delete Button
              Positioned(
                right: -12,
                top: -12,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onDelete();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x66FFFFFF), width: 1.2),
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
