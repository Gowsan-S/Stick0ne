import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/canvas_provider.dart';
import '../widgets/stick0ne_logo.dart';

class PreviewDisplayModal extends StatefulWidget {
  final Uint8List imageBytes;
  final Uint8List transparentBytes;

  const PreviewDisplayModal({
    super.key,
    required this.imageBytes,
    required this.transparentBytes,
  });

  @override
  State<PreviewDisplayModal> createState() => _PreviewDisplayModalState();
}

class _PreviewDisplayModalState extends State<PreviewDisplayModal> {
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isSuccess = false;
  bool _isXiaomi = false;

  @override
  void initState() {
    super.initState();
    _checkXiaomi();
  }

  Future<void> _checkXiaomi() async {
    final isXiaomi = await context.read<CanvasProvider>().isXiaomiDevice();
    if (mounted) {
      setState(() => _isXiaomi = isXiaomi);
    }
  }

  Future<void> _stickToScreen() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    final canvasProvider = context.read<CanvasProvider>();
    final result = await canvasProvider.stickToScreen(widget.transparentBytes);

    if (!mounted) return;

    if (result.permissionNeeded) {
      setState(() => _isProcessing = false);
      _showPermissionDialog();
      return;
    }

    setState(() {
      _isProcessing = false;
      _statusMessage = result.message;
      _isSuccess = result.success;
    });

    if (result.success) {
      await canvasProvider.saveCurrentDesign(thumbnailBytes: widget.imageBytes);
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _removeFromScreen() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    final canvasProvider = context.read<CanvasProvider>();
    final success = await canvasProvider.removeFromScreen();

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isSuccess = success;
      _statusMessage = success
          ? 'Sticker removed from your screen.'
          : 'Failed to remove sticker.';
    });
  }

  void _showPermissionDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'To stick stickers directly onto your phone screen (floating over your launcher and apps), please enable "Appear on top" in system settings.',
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
              await context.read<CanvasProvider>().requestOverlayPermission();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canvasProvider = context.watch<CanvasProvider>();
    final isOverlayActive = canvasProvider.isOverlayActive;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.90,
          decoration: BoxDecoration(
            color: const Color(0xF0141416),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
          ),
          child: Column(
            children: [
              // iOS Grabber bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF48484A),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Stick0neLogo(height: 14, color: Color(0xFFE5E5EA)),
                        SizedBox(height: 4),
                        Text(
                          'Stick to Screen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Stick0ne Display Engine',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2C2C2E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          color: Color(0xFF8E8E93),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Pure Stick to Screen View (No Wallpaper / Widgets options)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    children: [
                      // Live Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isOverlayActive
                                  ? const Color(0x3330D158)
                                  : const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isOverlayActive
                                    ? const Color(0xFF30D158)
                                    : const Color(0x33FFFFFF),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isOverlayActive
                                        ? const Color(0xFF30D158)
                                        : const Color(0xFF8E8E93),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isOverlayActive ? 'STUCK ON SCREEN (ACTIVE)' : 'NOT ON SCREEN',
                                  style: TextStyle(
                                    color: isOverlayActive
                                        ? const Color(0xFF30D158)
                                        : const Color(0xFF8E8E93),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Live Phone Display Mockup
                      Container(
                        height: 320,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0x33FFFFFF), width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 28,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Simulated phone launcher background icons
                              _buildSimulatedLauncherBackground(),

                              // The Transparent Stickers stuck on top!
                              Image.memory(
                                widget.transparentBytes,
                                fit: BoxFit.contain,
                              ),

                              // Glass glare effect
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 90,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Color(0x1AFFFFFF), Colors.transparent],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Feature & Concept Explanation Cards
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
                        ),
                        child: Column(
                          children: [
                            _buildFeatureRow(
                              icon: CupertinoIcons.hand_draw,
                              title: 'Touch Pass-Through',
                              desc: 'Touches pass straight through to your apps and launcher underneath.',
                            ),
                            const Divider(color: Color(0x1AFFFFFF), height: 18),
                            _buildFeatureRow(
                              icon: CupertinoIcons.lock_shield,
                              title: 'Fixed in Place (Feature 4)',
                              desc: 'Stickers cannot be dragged outside Stick0ne. Reopen app to move or edit.',
                            ),
                            const Divider(color: Color(0x1AFFFFFF), height: 18),
                            _buildFeatureRow(
                              icon: CupertinoIcons.photo_fill_on_rectangle_fill,
                              title: 'Zero Wallpaper Disruption',
                              desc: 'Your personal wallpapers remain 100% intact. Stickers float on top.',
                            ),
                          ],
                        ),
                      ),

                      // Xiaomi / MIUI / HyperOS Special Setup Card for floating over other apps
                      if (_isXiaomi) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0x26FF9F0A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x66FF9F0A), width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Color(0xFFFF9F0A), size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Xiaomi / Redmi / POCO Setup',
                                    style: TextStyle(
                                      color: Color(0xFFFF9F0A),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'To keep stickers floating when you open other apps, enable "Display pop-up windows while running in the background" in Xiaomi settings.',
                                style: TextStyle(color: Colors.white, fontSize: 12, height: 1.35),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => context.read<CanvasProvider>().openMiuiPermissionSettings(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9F0A),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(CupertinoIcons.gear_alt_fill, color: Colors.black, size: 13),
                                      SizedBox(width: 6),
                                      Text(
                                        'Open Xiaomi Permissions',
                                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_statusMessage != null) ...[
                        const SizedBox(height: 14),
                        _buildStatusBanner(),
                      ],

                      const SizedBox(height: 20),

                      if (_isProcessing)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CupertinoActivityIndicator(color: Colors.white, radius: 14),
                        )
                      else ...[
                        // Apple White Primary Button: Stick to Screen
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _stickToScreen,
                            icon: Icon(
                              isOverlayActive ? CupertinoIcons.arrow_2_circlepath : CupertinoIcons.pin_fill,
                              color: Colors.black,
                              size: 18,
                            ),
                            label: Text(
                              isOverlayActive ? 'Update on Screen' : 'Stick to Screen Now',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                          ),
                        ),

                        if (isOverlayActive) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _removeFromScreen,
                              icon: const Icon(CupertinoIcons.xmark_circle, color: Color(0xFFFF453A), size: 18),
                              label: const Text(
                                'Remove from Screen',
                                style: TextStyle(
                                  color: Color(0xFFFF453A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0x33FF453A)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isSuccess ? const Color(0xFF1C1C1E) : const Color(0x33FF453A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isSuccess ? Colors.white : const Color(0xFFFF453A),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isSuccess ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.exclamationmark_circle_fill,
            color: _isSuccess ? Colors.white : const Color(0xFFFF453A),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: _isSuccess ? Colors.white : const Color(0xFFFF453A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedLauncherBackground() {
    return Container(
      color: const Color(0xFF0F0F12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Clock & date
          const Text(
            '9:41',
            style: TextStyle(
              color: Color(0x4DFFFFFF),
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // App icons grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (i) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Dock
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (i) => Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
