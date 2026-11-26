import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/saved_design.dart';
import '../models/sticker_item.dart';
import '../models/sticker_placement.dart';
import '../services/screen_overlay_service.dart';
import '../services/storage_service.dart';
import '../services/wallpaper_service.dart';

enum PreviewOverlayMode {
  none,
  homeScreen,
  lockScreen,
}

class CanvasProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final WallpaperService _wallpaperService = WallpaperService();
  final ScreenOverlayService _overlayService = ScreenOverlayService();
  final _uuid = const Uuid();

  // Active Canvas State
  String? _currentDesignId;
  String _currentDesignName = 'Untitled Sticker Screen';
  BackgroundType _backgroundType = BackgroundType.transparent;
  Color _solidColor = const Color(0xFF000000); // Pure OLED Black
  List<Color> _gradientColors = [
    const Color(0xFF000000),
    const Color(0xFF1C1C1E),
  ];
  double _gradientAngle = 45.0;
  String? _bgImagePath;

  List<StickerPlacement> _placements = [];
  String? _selectedPlacementId;
  PreviewOverlayMode _previewOverlay = PreviewOverlayMode.none;

  // Saved Designs list
  List<SavedDesign> _savedDesigns = [];
  bool _isLoadingDesigns = true;
  bool _isOverlayActive = false;

  CanvasProvider() {
    _loadSavedDesigns();
    checkOverlayStatus();
  }

  // Getters
  String? get currentDesignId => _currentDesignId;
  String get currentDesignName => _currentDesignName;
  BackgroundType get backgroundType => _backgroundType;
  Color get solidColor => _solidColor;
  List<Color> get gradientColors => _gradientColors;
  double get gradientAngle => _gradientAngle;
  String? get bgImagePath => _bgImagePath;
  List<StickerPlacement> get placements => _placements;
  String? get selectedPlacementId => _selectedPlacementId;
  PreviewOverlayMode get previewOverlay => _previewOverlay;
  List<SavedDesign> get savedDesigns => _savedDesigns;
  bool get isLoadingDesigns => _isLoadingDesigns;
  bool get isOverlayActive => _isOverlayActive;

  @visibleForTesting
  void setOverlayActiveForTest(bool active) {
    _isOverlayActive = active;
    notifyListeners();
  }

  StickerPlacement? get selectedPlacement {
    if (_selectedPlacementId == null) return null;
    try {
      return _placements.firstWhere((p) => p.id == _selectedPlacementId);
    } catch (_) {
      return null;
    }
  }

  void setDesignName(String name) {
    _currentDesignName = name;
    notifyListeners();
  }

  void setPreviewOverlay(PreviewOverlayMode mode) {
    _previewOverlay = mode;
    notifyListeners();
  }

  void setBackgroundType(BackgroundType type) {
    _backgroundType = type;
    notifyListeners();
  }

  void setTransparentBackground() {
    _backgroundType = BackgroundType.transparent;
    notifyListeners();
  }

  void setSolidColor(Color color) {
    _solidColor = color;
    _backgroundType = BackgroundType.color;
    notifyListeners();
  }

  void setGradient(List<Color> colors, [double angle = 45.0]) {
    _gradientColors = colors;
    _gradientAngle = angle;
    _backgroundType = BackgroundType.gradient;
    notifyListeners();
  }

  void setBgImage(String? imagePath) {
    _bgImagePath = imagePath;
    if (imagePath != null) {
      _backgroundType = BackgroundType.image;
    }
    notifyListeners();
  }

  // Sticker Placement management
  void addSticker(StickerItem sticker) {
    final count = _placements.length;
    // Stagger multiple stickers slightly so each added sticker is immediately visible & separate
    final offsetX = ((count % 4) - 1.5) * 0.12;
    final offsetY = ((count ~/ 4 % 3) - 0.5) * 0.12;
    final newPlacement = StickerPlacement(
      id: _uuid.v4(),
      sticker: sticker,
      x: (0.5 + offsetX).clamp(0.2, 0.8),
      y: (0.45 + offsetY).clamp(0.2, 0.75),
      scale: 1.0,
      rotation: 0.0,
      opacity: 1.0,
    );
    _placements.add(newPlacement);
    _selectedPlacementId = newPlacement.id;
    notifyListeners();
  }

  void selectPlacement(String? id) {
    _selectedPlacementId = id;
    notifyListeners();
  }

  void updatePlacementPosition(String id, double x, double y) {
    final index = _placements.indexWhere((p) => p.id == id);
    if (index != -1) {
      _placements[index] = _placements[index].copyWith(x: x, y: y);
      notifyListeners();
    }
  }

  void updatePlacementScale(String id, double scale) {
    final index = _placements.indexWhere((p) => p.id == id);
    if (index != -1) {
      _placements[index] = _placements[index].copyWith(scale: scale.clamp(0.2, 4.0));
      notifyListeners();
    }
  }

  void updatePlacementRotation(String id, double rotation) {
    final index = _placements.indexWhere((p) => p.id == id);
    if (index != -1) {
      _placements[index] = _placements[index].copyWith(rotation: rotation);
      notifyListeners();
    }
  }

  void updatePlacementOpacity(String id, double opacity) {
    final index = _placements.indexWhere((p) => p.id == id);
    if (index != -1) {
      _placements[index] = _placements[index].copyWith(opacity: opacity.clamp(0.05, 1.0));
      notifyListeners();
    }
  }

  void duplicatePlacement(String id) {
    try {
      final original = _placements.firstWhere((p) => p.id == id);
      final duplicate = original.copyWith(
        id: _uuid.v4(),
        x: (original.x + 0.04).clamp(0.05, 0.95),
        y: (original.y + 0.04).clamp(0.05, 0.95),
      );
      _placements.add(duplicate);
      _selectedPlacementId = duplicate.id;
      notifyListeners();
    } catch (_) {}
  }

  void removePlacement(String id) {
    _placements.removeWhere((p) => p.id == id);
    if (_selectedPlacementId == id) {
      _selectedPlacementId = _placements.isNotEmpty ? _placements.last.id : null;
    }
    if (_placements.isEmpty && _isOverlayActive) {
      removeFromScreen();
    }
    notifyListeners();
  }

  void bringPlacementToFront(String id) {
    final index = _placements.indexWhere((p) => p.id == id);
    if (index != -1 && index < _placements.length - 1) {
      final item = _placements.removeAt(index);
      _placements.add(item);
      notifyListeners();
    }
  }

  void sendPlacementToBack(String id) {
    final index = _placements.indexWhere((p) => p.id == id);
    if (index > 0) {
      final item = _placements.removeAt(index);
      _placements.insert(0, item);
      notifyListeners();
    }
  }

  Future<void> resetCanvas({String? initialName}) async {
    if (_isOverlayActive) {
      await removeFromScreen();
    }
    _currentDesignId = null;
    _currentDesignName = initialName ?? 'New Sticker Setup';
    _backgroundType = BackgroundType.transparent;
    _solidColor = const Color(0xFF000000);
    _gradientColors = const [Color(0xFF000000), Color(0xFF1C1C1E)];
    _bgImagePath = null;
    _placements = [];
    _selectedPlacementId = null;
    _previewOverlay = PreviewOverlayMode.none;
    notifyListeners();
  }

  // Saved designs management
  Future<void> _loadSavedDesigns() async {
    _isLoadingDesigns = true;
    notifyListeners();
    _savedDesigns = await _storageService.loadSavedDesigns();
    _isLoadingDesigns = false;
    notifyListeners();
  }

  Future<void> saveCurrentDesign({Uint8List? thumbnailBytes}) async {
    String? thumbPath;
    if (thumbnailBytes != null) {
      final filename = 'thumb_${DateTime.now().millisecondsSinceEpoch}.png';
      thumbPath = await _storageService.saveRenderedWallpaper(thumbnailBytes, filename);
    }

    final id = _currentDesignId ?? _uuid.v4();
    final newDesign = SavedDesign(
      id: id,
      name: _currentDesignName,
      backgroundType: _backgroundType,
      solidColorValue: _solidColor.toARGB32(),
      gradientColorValues: _gradientColors.map((c) => c.toARGB32()).toList(),
      gradientAngle: _gradientAngle,
      bgImagePath: _bgImagePath,
      placements: List<StickerPlacement>.from(_placements),
      thumbnailPath: thumbPath,
      updatedAt: DateTime.now(),
    );

    final existingIndex = _savedDesigns.indexWhere((d) => d.id == id);
    if (existingIndex != -1) {
      _savedDesigns[existingIndex] = newDesign;
    } else {
      _savedDesigns.insert(0, newDesign);
    }

    _currentDesignId = id;
    await _storageService.saveDesigns(_savedDesigns);
    notifyListeners();
  }

  void loadDesign(SavedDesign design) {
    _currentDesignId = design.id;
    _currentDesignName = design.name;
    _backgroundType = design.backgroundType;
    _solidColor = Color(design.solidColorValue);
    _gradientColors = design.gradientColorValues.map((v) => Color(v)).toList();
    _gradientAngle = design.gradientAngle;
    _bgImagePath = design.bgImagePath;
    _placements = design.placements
        .map((p) => p.copyWith(id: _uuid.v4()))
        .toList();
    _selectedPlacementId = _placements.isNotEmpty ? _placements.first.id : null;
    _previewOverlay = PreviewOverlayMode.none;
    notifyListeners();
  }

  Future<void> deleteDesign(String id) async {
    _savedDesigns.removeWhere((d) => d.id == id);
    if (_currentDesignId == id) {
      _currentDesignId = null;
    }
    await _storageService.saveDesigns(_savedDesigns);
    notifyListeners();
  }

  // --- SCREEN OVERLAY ENGINE (Features 3, 4, 5: Stick to Screen) ---
  Future<void> checkOverlayStatus() async {
    _isOverlayActive = await _overlayService.isOverlayActive();
    notifyListeners();
  }

  Future<bool> canDrawOverlays() async {
    return await _overlayService.canDrawOverlays();
  }

  Future<bool> isXiaomiDevice() async {
    return await _overlayService.isXiaomiDevice();
  }

  Future<bool> openMiuiPermissionSettings() async {
    return await _overlayService.openMiuiPermissionSettings();
  }

  Future<bool> requestOverlayPermission() async {
    return await _overlayService.requestOverlayPermission();
  }

  Future<OverlayResult> stickToScreen(Uint8List transparentBytes) async {
    final result = await _overlayService.stickToScreen(transparentBytes);
    if (result.success) {
      _isOverlayActive = true;
      notifyListeners();
    }
    return result;
  }

  Future<bool> removeFromScreen() async {
    final success = await _overlayService.removeFromScreen();
    if (success) {
      _isOverlayActive = false;
      notifyListeners();
    }
    return success;
  }

  // --- WALLPAPER EXPORT (Fallback & Dual-Mode) ---
  Future<WallpaperResult> applyToScreen({
    required Uint8List renderedBytes,
    required WallpaperLocation location,
  }) async {
    final result = await _wallpaperService.applyWallpaper(
      imageBytes: renderedBytes,
      location: location,
    );
    return result;
  }
}
