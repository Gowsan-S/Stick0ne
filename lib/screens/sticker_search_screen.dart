import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/sticker_item.dart';
import '../providers/canvas_provider.dart';
import '../providers/sticker_provider.dart';
import '../widgets/vector_stickers.dart';

class StickerSearchScreen extends StatefulWidget {
  final VoidCallback onNavigateToCanvas;

  const StickerSearchScreen({
    super.key,
    required this.onNavigateToCanvas,
  });

  @override
  State<StickerSearchScreen> createState() => _StickerSearchScreenState();
}

class _StickerSearchScreenState extends State<StickerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stickerProvider = context.watch<StickerProvider>();
    final stickers = stickerProvider.filteredStickers;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIosHeader(context),
            _buildIosSearchBar(stickerProvider),
            const SizedBox(height: 4),
            _buildIosCategoryPills(stickerProvider),
            const SizedBox(height: 8),
            Expanded(
              child: stickerProvider.isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(color: Colors.white, radius: 14),
                    )
                  : stickers.isEmpty
                      ? _buildEmptyState(stickerProvider)
                      : _buildStickerGrid(stickers),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIosHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'STICK0NE',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Explore Stickers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x33FFFFFF), width: 0.8),
            ),
            child: const Icon(
              CupertinoIcons.sparkles,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIosSearchBar(StickerProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(CupertinoIcons.search, color: Color(0xFF8E8E93), size: 18),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: provider.setSearchQuery,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search stickers, tags, emojis...',
                  hintStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(CupertinoIcons.clear_circled_solid,
                      color: Color(0xFF8E8E93), size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIosCategoryPills(StickerProvider provider) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: provider.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = provider.categories[index];
          final isSelected = provider.selectedCategory == category;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              provider.selectCategory(category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.white : const Color(0x26FFFFFF),
                  width: 0.8,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.black : const Color(0xFFEBEBF5),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStickerGrid(List<StickerItem> stickers) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100), // bottom padding for floating tab bar
      itemCount: stickers.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final sticker = stickers[index];
        return _buildStickerCard(context, sticker);
      },
    );
  }

  Widget _buildStickerCard(BuildContext context, StickerItem sticker) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        final canvas = context.read<CanvasProvider>();
        if (canvas.placements.isEmpty) {
          canvas.setDesignName('${sticker.title} Setup');
        }
        canvas.addSticker(sticker);
        widget.onNavigateToCanvas();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        final canvas = context.read<CanvasProvider>();
        if (canvas.placements.isEmpty) {
          canvas.setDesignName('${sticker.title} Setup');
        }
        canvas.addSticker(sticker);
        widget.onNavigateToCanvas();
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x1AFFFFFF), width: 0.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Hero(
                  tag: 'sticker_${sticker.id}',
                  child: StickerDisplayWidget(
                    sticker: sticker,
                    size: 64,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
              child: Text(
                sticker.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(StickerProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.search, size: 54, color: Color(0xFF48484A)),
          const SizedBox(height: 16),
          Text(
            provider.searchQuery.isNotEmpty
                ? 'No Results for "${provider.searchQuery}"'
                : 'No Stickers Available',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try another search or make a custom one',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
