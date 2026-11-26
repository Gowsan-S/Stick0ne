import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sticker_item.dart';
import '../models/saved_design.dart';

class StorageService {
  static const String _customStickersKey = 'stick0ne_custom_stickers';
  static const String _savedDesignsKey = 'stick0ne_saved_designs';

  Future<List<StickerItem>> loadCustomStickers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_customStickersKey) ?? [];
      return list.map((jsonStr) => StickerItem.fromJson(jsonStr)).toList();
    } catch (e) {
      debugPrint('Error loading custom stickers: $e');
      return [];
    }
  }

  Future<void> saveCustomStickers(List<StickerItem> stickers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = stickers.map((s) => s.toJson()).toList();
      await prefs.setStringList(_customStickersKey, list);
    } catch (e) {
      debugPrint('Error saving custom stickers: $e');
    }
  }

  Future<String> saveStickerImageFile(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final stickersDir = Directory('${dir.path}/stickers');
    if (!await stickersDir.exists()) {
      await stickersDir.create(recursive: true);
    }
    final file = File('${stickersDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<List<SavedDesign>> loadSavedDesigns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_savedDesignsKey) ?? [];
      return list.map((jsonStr) => SavedDesign.fromJson(jsonStr)).toList();
    } catch (e) {
      debugPrint('Error loading saved designs: $e');
      return [];
    }
  }

  Future<void> saveDesigns(List<SavedDesign> designs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = designs.map((d) => d.toJson()).toList();
      await prefs.setStringList(_savedDesignsKey, list);
    } catch (e) {
      debugPrint('Error saving designs: $e');
    }
  }

  Future<String> saveRenderedWallpaper(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final wallpaperDir = Directory('${dir.path}/wallpapers');
    if (!await wallpaperDir.exists()) {
      await wallpaperDir.create(recursive: true);
    }
    final file = File('${wallpaperDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
