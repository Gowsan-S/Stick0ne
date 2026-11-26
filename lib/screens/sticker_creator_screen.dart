import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/sticker_item.dart';
import '../providers/canvas_provider.dart';
import '../providers/sticker_provider.dart';
import '../services/storage_service.dart';
import '../widgets/drawing_canvas.dart';
import 'photo_cutter_screen.dart';

class StickerCreatorScreen extends StatefulWidget {
  final VoidCallback onNavigateToCanvas;

  const StickerCreatorScreen({
    super.key,
    required this.onNavigateToCanvas,
  });

  @override
  State<StickerCreatorScreen> createState() => _StickerCreatorScreenState();
}

class _StickerCreatorScreenState extends State<StickerCreatorScreen> {
  int _selectedTabIndex = 0; // 0: Doodle, 1: Text Badge, 2: Photo
  final StorageService _storageService = StorageService();
  final _uuid = const Uuid();

  // Tab 0: Doodle
  final GlobalKey _drawingKey = GlobalKey();
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey<DrawingCanvasState>();
  Color _doodleColor = Colors.white; // Default Apple White
  double _strokeWidth = 6.0;
  bool _isEraser = false;
  final TextEditingController _doodleTitleController =
      TextEditingController(text: 'Custom Doodle');

  // Tab 1: Text / Badge
  final TextEditingController _textContentController =
      TextEditingController(text: 'STICK0NE');
  final TextEditingController _textTitleController =
      TextEditingController(text: 'Text Sticker');
  Color _textColor = Colors.white;
  Color _textBorderColor = Colors.white;
  Color _textBgColor = Colors.black;

  // Tab 2: Photo Import
  File? _importedPhoto;
  Uint8List? _cutPhotoBytes;
  final TextEditingController _photoTitleController =
      TextEditingController(text: 'Photo Cutout');
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _doodleTitleController.dispose();
    _textContentController.dispose();
    _textTitleController.dispose();
    _photoTitleController.dispose();
    super.dispose();
  }

  Future<void> _saveDoodleSticker() async {
    final state = _canvasKey.currentState;
    if (state == null || state.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2C2C2E),
          content: Text('Draw something on the canvas first!', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    final pngBytes = await state.exportToPng();
    if (!mounted) return;
    if (pngBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2C2C2E),
          content: Text('Failed to generate sticker image.', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    final filename = 'doodle_${_uuid.v4()}.png';
    final savedPath = await _storageService.saveStickerImageFile(pngBytes, filename);

    if (!mounted) return;
    final newSticker = StickerItem(
      id: _uuid.v4(),
      title: _doodleTitleController.text.trim().isEmpty
          ? 'Custom Doodle'
          : _doodleTitleController.text.trim(),
      category: 'My Stickers',
      type: StickerType.image,
      data: savedPath,
      isCustom: true,
      tags: ['custom', 'doodle', 'monochrome'],
    );

    final stickerProvider = context.read<StickerProvider>();
    final canvasProvider = context.read<CanvasProvider>();

    await stickerProvider.addCustomSticker(newSticker);
    canvasProvider.addSticker(newSticker);

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2C2C2E),
        content: Text('Created "${newSticker.title}" and placed on canvas', style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    widget.onNavigateToCanvas();
  }

  Future<void> _saveTextSticker() async {
    final text = _textContentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2C2C2E),
          content: Text('Please enter sticker text!', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    final newSticker = StickerItem(
      id: _uuid.v4(),
      title: _textTitleController.text.trim().isEmpty ? text : _textTitleController.text.trim(),
      category: 'My Stickers',
      type: StickerType.text,
      data: text,
      isCustom: true,
      tags: ['custom', 'text', 'badge', text.toLowerCase()],
    );

    if (!mounted) return;
    final stickerProvider = context.read<StickerProvider>();
    final canvasProvider = context.read<CanvasProvider>();

    await stickerProvider.addCustomSticker(newSticker);
    canvasProvider.addSticker(newSticker);

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2C2C2E),
        content: Text('Created text badge "${newSticker.title}"!', style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    widget.onNavigateToCanvas();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 95,
      );
      if (picked != null) {
        setState(() {
          _importedPhoto = File(picked.path);
          _cutPhotoBytes = null; // Reset prior cut on new image import
        });
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2C2C2E),
          content: Text('Failed to pick photo: $e', style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  Future<void> _openPhotoCutter() async {
    if (_importedPhoto == null) return;
    HapticFeedback.mediumImpact();
    final bytes = await _importedPhoto!.readAsBytes();
    if (!mounted) return;

    final cutBytes = await Navigator.push<Uint8List>(
      context,
      CupertinoPageRoute(
        builder: (_) => PhotoCutterScreen(imageBytes: bytes),
      ),
    );

    if (cutBytes != null && mounted) {
      setState(() {
        _cutPhotoBytes = cutBytes;
        if (_photoTitleController.text.trim().isEmpty ||
            _photoTitleController.text == 'Photo Cutout' ||
            _photoTitleController.text == 'Photo Sticker') {
          _photoTitleController.text = 'Custom Photo Cutout';
        }
      });
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1C1C1E),
          content: const Text(
            'Photo cut successfully! Ready to place on screen.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _savePhotoSticker() async {
    if (_importedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2C2C2E),
          content: Text('Please select a photo first!', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    final bytes = _cutPhotoBytes ?? await _importedPhoto!.readAsBytes();
    final filename = 'photo_${_uuid.v4()}.png';
    final savedPath = await _storageService.saveStickerImageFile(bytes, filename);

    if (!mounted) return;
    final newSticker = StickerItem(
      id: _uuid.v4(),
      title: _photoTitleController.text.trim().isEmpty
          ? (_cutPhotoBytes != null ? 'Photo Cutout' : 'Photo Sticker')
          : _photoTitleController.text.trim(),
      category: 'My Stickers',
      type: StickerType.image,
      data: savedPath,
      isCustom: true,
      tags: ['custom', 'photo', if (_cutPhotoBytes != null) 'cutout'],
    );

    final stickerProvider = context.read<StickerProvider>();
    final canvasProvider = context.read<CanvasProvider>();

    await stickerProvider.addCustomSticker(newSticker);
    canvasProvider.addSticker(newSticker);

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2C2C2E),
        content: Text('Created photo sticker "${newSticker.title}"!', style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    widget.onNavigateToCanvas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIosHeader(),
            _buildIosSegmentedControl(),
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  _buildDoodleTab(),
                  _buildTextStickerTab(),
                  _buildPhotoStickerTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIosHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'STUDIO',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Create Sticker',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIosSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
      ),
      child: Row(
        children: [
          _buildSegmentButton(0, CupertinoIcons.pencil, 'Doodle'),
          _buildSegmentButton(1, CupertinoIcons.textbox, 'Badge'),
          _buildSegmentButton(2, CupertinoIcons.photo, 'Photo'),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, IconData icon, String title) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.black : const Color(0xFF8E8E93),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.black : const Color(0xFF8E8E93),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 0: Apple-Style Monochrome Doodle Studio
  Widget _buildDoodleTab() {
    // Monochromatic Black, Grays & White palette
    const monochromeColors = [
      Colors.white,
      Color(0xFFE5E5EA), // Light Gray
      Color(0xFF8E8E93), // Mid Zinc
      Color(0xFF48484A), // Dark Slate
      Color(0xFF2C2C2E), // Deep Charcoal
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Apple Drawing Canvas Area
          Container(
            height: 310,
            decoration: BoxDecoration(
              color: const Color(0xFF141416),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x26FFFFFF), width: 1.0),
            ),
            child: Stack(
              children: [
                DrawingCanvas(
                  key: _canvasKey,
                  repaintKey: _drawingKey,
                  selectedColor: _doodleColor,
                  strokeWidth: _strokeWidth,
                  isEraser: _isEraser,
                ),
                // Top control buttons (Undo, Eraser, Clear)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _buildCupertinoRoundBtn(
                        icon: CupertinoIcons.arrow_uturn_left,
                        tooltip: 'Undo',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _canvasKey.currentState?.undo();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildCupertinoRoundBtn(
                        icon: _isEraser ? CupertinoIcons.pencil : CupertinoIcons.bandage,
                        tooltip: _isEraser ? 'Draw' : 'Eraser',
                        isActive: _isEraser,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isEraser = !_isEraser);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildCupertinoRoundBtn(
                        icon: CupertinoIcons.trash,
                        tooltip: 'Clear',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _canvasKey.currentState?.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Monochrome Palette
          Row(
            children: [
              ...monochromeColors.map((color) {
                final isSelected = !_isEraser && _doodleColor == color;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _doodleColor = color;
                      _isEraser = false;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : const Color(0x40FFFFFF),
                        width: isSelected ? 3.0 : 1.0,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),
          // Stroke Slider (iOS style)
          Row(
            children: [
              const Text(
                'Stroke',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: Slider(
                  value: _strokeWidth,
                  min: 2.0,
                  max: 22.0,
                  activeColor: Colors.white,
                  inactiveColor: const Color(0xFF2C2C2E),
                  onChanged: (val) => setState(() => _strokeWidth = val),
                ),
              ),
              Text(
                '${_strokeWidth.toInt()}pt',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title Input (iOS Inset TextField)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
            ),
            child: TextField(
              controller: _doodleTitleController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Sticker Name (e.g. Star Doodle)',
                hintStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Apple White Primary Button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saveDoodleSticker,
              icon: const Icon(CupertinoIcons.checkmark_alt, color: Colors.black, size: 20),
              label: const Text(
                'Save & Place on Canvas',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoRoundBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.white : const Color(0xCC2C2C2E),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x33FFFFFF), width: 0.8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: isActive ? Colors.black : Colors.white),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }

  // TAB 1: Text & Badge Maker
  Widget _buildTextStickerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Monochromatic High-Contrast Badge Preview
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF141416),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x26FFFFFF), width: 1.0),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                decoration: BoxDecoration(
                  color: _textBgColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _textBorderColor, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _textContentController.text.isEmpty
                      ? 'BADGE'
                      : _textContentController.text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 2.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Text Input Field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
            ),
            child: TextField(
              controller: _textContentController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Badge Text (e.g. FOCUS, CHILL)',
                hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Black / White Toggle Styles
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _textColor = Colors.white;
                      _textBgColor = Colors.black;
                      _textBorderColor = Colors.white;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _textBgColor == Colors.black ? Colors.white : const Color(0x26FFFFFF),
                        width: _textBgColor == Colors.black ? 2.0 : 0.8,
                      ),
                    ),
                    child: const Text(
                      'Dark Inset',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _textColor = Colors.black;
                      _textBgColor = Colors.white;
                      _textBorderColor = Colors.white;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _textBgColor == Colors.white ? Colors.white : const Color(0x26FFFFFF),
                        width: _textBgColor == Colors.white ? 2.0 : 0.8,
                      ),
                    ),
                    child: const Text(
                      'Light Inset',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Sticker Name Field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
            ),
            child: TextField(
              controller: _textTitleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Sticker Name (e.g. Focus Badge)',
                hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saveTextSticker,
              icon: const Icon(CupertinoIcons.checkmark_alt, color: Colors.black, size: 20),
              label: const Text(
                'Save & Place Badge on Canvas',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: Photo Importer
  Widget _buildPhotoStickerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 270,
            decoration: BoxDecoration(
              color: const Color(0xFF141416),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x26FFFFFF), width: 1.0),
            ),
            child: _importedPhoto != null
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      // Photo or Cutout Preview
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _cutPhotoBytes != null
                              ? Image.memory(_cutPhotoBytes!, fit: BoxFit.contain)
                              : Image.file(_importedPhoto!, fit: BoxFit.contain),
                        ),
                      ),

                      // Status Badge for Cutout
                      if (_cutPhotoBytes != null)
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xCC000000),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x4D30D158), width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.scissors, color: Color(0xFF30D158), size: 12),
                                SizedBox(width: 5),
                                Text(
                                  'CUTOUT (TRANSPARENT)',
                                  style: TextStyle(
                                    color: Color(0xFF30D158),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Replace photo button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _pickPhoto(ImageSource.gallery),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xCC000000),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(CupertinoIcons.arrow_2_circlepath, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0x26FFFFFF)),
                          ),
                          child: const Icon(CupertinoIcons.photo_on_rectangle, size: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Import Photo for Sticker',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Turn photos into clean screen stickers',
                          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _pickPhoto(ImageSource.gallery),
                              icon: const Icon(CupertinoIcons.photo, size: 16),
                              label: const Text('Photos'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Color(0x33FFFFFF)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => _pickPhoto(ImageSource.camera),
                              icon: const Icon(CupertinoIcons.camera, size: 16),
                              label: const Text('Camera'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Color(0x33FFFFFF)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),

          if (_importedPhoto != null) ...[
            const SizedBox(height: 12),

            // Cut Photo Action Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _openPhotoCutter,
                icon: const Icon(CupertinoIcons.scissors, color: Colors.black, size: 18),
                label: Text(
                  _cutPhotoBytes != null ? 'Cut Again' : 'Cut Photo (Lasso & Shapes)',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            if (_cutPhotoBytes != null) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _cutPhotoBytes = null);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  alignment: Alignment.center,
                  child: const Text(
                    'Reset to Original Uncut Photo',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
            ),
            child: TextField(
              controller: _photoTitleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Sticker Name (e.g. My Photo Cutout)',
                hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _importedPhoto != null ? _savePhotoSticker : null,
              icon: const Icon(CupertinoIcons.checkmark_alt, color: Colors.black, size: 20),
              label: const Text(
                'Save & Place Photo Sticker',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF2C2C2E),
                disabledForegroundColor: const Color(0xFF8E8E93),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
