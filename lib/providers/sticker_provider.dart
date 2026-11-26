import 'package:flutter/foundation.dart';
import '../data/default_stickers.dart';
import '../models/sticker_item.dart';
import '../services/storage_service.dart';

class StickerProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<StickerItem> _allStickers = [];
  List<StickerItem> _customStickers = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = true;

  StickerProvider() {
    _initStickers();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<String> get categories => DefaultStickers.categories;

  List<StickerItem> get customStickers => _customStickers;
  List<StickerItem> get allStickers => _allStickers;
  List<StickerItem> get stickers => _allStickers;

  List<StickerItem> get filteredStickers {
    return _allStickers.where((sticker) {
      final matchesCategory = _selectedCategory == 'All' ||
          (_selectedCategory == 'My Stickers' && sticker.isCustom) ||
          sticker.category.toLowerCase() == _selectedCategory.toLowerCase();

      if (!matchesCategory) return false;

      if (_searchQuery.trim().isEmpty) return true;

      final query = _searchQuery.toLowerCase().trim();
      final titleMatch = sticker.title.toLowerCase().contains(query);
      final categoryMatch = sticker.category.toLowerCase().contains(query);
      final tagsMatch =
          sticker.tags.any((tag) => tag.toLowerCase().contains(query));
      final textDataMatch = sticker.type == StickerType.text &&
          sticker.data.toLowerCase().contains(query);

      return titleMatch || categoryMatch || tagsMatch || textDataMatch;
    }).toList();
  }

  Future<void> _initStickers() async {
    _isLoading = true;
    notifyListeners();

    _customStickers = await _storageService.loadCustomStickers();
    _rebuildAllStickers();

    _isLoading = false;
    notifyListeners();
  }

  void _rebuildAllStickers() {
    _allStickers = [
      ..._customStickers,
      ...DefaultStickers.allStickers,
    ];
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> addCustomSticker(StickerItem sticker) async {
    _customStickers.insert(0, sticker);
    _rebuildAllStickers();
    await _storageService.saveCustomStickers(_customStickers);
    notifyListeners();
  }

  Future<void> deleteCustomSticker(String stickerId) async {
    _customStickers.removeWhere((s) => s.id == stickerId);
    _rebuildAllStickers();
    await _storageService.saveCustomStickers(_customStickers);
    notifyListeners();
  }
}
