import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/saved_design.dart';
import '../providers/canvas_provider.dart';

class MyDesignsScreen extends StatelessWidget {
  final VoidCallback onNavigateToCanvas;

  const MyDesignsScreen({
    super.key,
    required this.onNavigateToCanvas,
  });

  @override
  Widget build(BuildContext context) {
    final canvasProvider = context.watch<CanvasProvider>();
    final designs = canvasProvider.savedDesigns;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIosHeader(context),
            Expanded(
              child: canvasProvider.isLoadingDesigns
                  ? const Center(
                      child: CupertinoActivityIndicator(color: Colors.white, radius: 14),
                    )
                  : designs.isEmpty
                      ? _buildEmptyState(context)
                      : _buildDesignsGrid(context, designs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIosHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'GALLERY',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'My Setups',
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

  Widget _buildDesignsGrid(BuildContext context, List<SavedDesign> designs) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110), // space for floating bottom bar
      itemCount: designs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final design = designs[index];
        return _buildDesignCard(context, design);
      },
    );
  }

  Widget _buildDesignCard(BuildContext context, SavedDesign design) {
    final canvasProvider = context.read<CanvasProvider>();

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        canvasProvider.loadDesign(design);
        onNavigateToCanvas();
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: design.thumbnailPath != null && File(design.thumbnailPath!).existsSync()
                    ? Image.file(
                        File(design.thumbnailPath!),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Color(design.solidColorValue),
                          gradient: design.backgroundType == BackgroundType.gradient
                              ? LinearGradient(
                                  colors: design.gradientColorValues.map((v) => Color(v)).toList(),
                                )
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.device_phone_portrait,
                            size: 40,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          design.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${design.placements.length} sticker${design.placements.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(CupertinoIcons.ellipsis, color: Color(0xFF8E8E93), size: 16),
                    color: const Color(0xFF2C2C2E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (value) {
                      if (value == 'edit') {
                        HapticFeedback.selectionClick();
                        canvasProvider.loadDesign(design);
                        onNavigateToCanvas();
                      } else if (value == 'delete') {
                        HapticFeedback.mediumImpact();
                        canvasProvider.deleteDesign(design.id);
                      }
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.pencil, color: Colors.white, size: 16),
                            SizedBox(width: 10),
                            Text('Edit Setup', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.trash, color: Color(0xFFFF453A), size: 16),
                            SizedBox(width: 10),
                            Text('Delete', style: TextStyle(color: Color(0xFFFF453A))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
            ),
            child: const Icon(
              CupertinoIcons.square_grid_2x2,
              size: 44,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No Setups Saved',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Personalize a screen setup with stickers\nand save it to edit or swap anytime.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              onNavigateToCanvas();
            },
            icon: const Icon(CupertinoIcons.plus, color: Colors.black, size: 18),
            label: const Text(
              'Create Setup',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }
}
