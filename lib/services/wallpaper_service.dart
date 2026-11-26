import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum WallpaperLocation {
  homeScreen(1),
  lockScreen(2),
  both(3);

  final int value;
  const WallpaperLocation(this.value);
}

class WallpaperResult {
  final bool success;
  final String message;
  final String? savedPath;

  WallpaperResult({
    required this.success,
    required this.message,
    this.savedPath,
  });
}

class WallpaperService {
  static const MethodChannel _channel =
      MethodChannel('com.stick0ne.app/wallpaper');

  /// Applies the rendered image as wallpaper.
  /// On Android: calls native WallpaperManager for Home, Lock, or Both.
  /// On iOS / other platforms: saves to device and opens the system Share/Action sheet
  /// allowing 1-tap "Save Image" or "Set as Wallpaper".
  Future<WallpaperResult> applyWallpaper({
    required Uint8List imageBytes,
    required WallpaperLocation location,
  }) async {
    try {
      // 1. Save locally first so the user also has the high-res file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'stick0ne_wallpaper_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      if (kIsWeb) {
        return WallpaperResult(
          success: true,
          message: 'Wallpaper generated successfully!',
          savedPath: file.path,
        );
      }

      if (Platform.isAndroid) {
        try {
          final bool? result = await _channel.invokeMethod<bool>(
            'setWallpaper',
            {
              'imageBytes': imageBytes,
              'location': location.value,
            },
          );

          if (result == true) {
            final locName = location == WallpaperLocation.homeScreen
                ? 'Home Screen'
                : location == WallpaperLocation.lockScreen
                    ? 'Lock Screen'
                    : 'Home & Lock Screen';
            return WallpaperResult(
              success: true,
              message: 'Sticker wallpaper successfully applied to $locName!',
              savedPath: file.path,
            );
          }
        } on PlatformException catch (e) {
          debugPrint('Android native wallpaper error: ${e.message}');
          // If native wallpaper failed for any reason, fallback to share sheet
          await Share.shareXFiles(
            [XFile(file.path, mimeType: 'image/png')],
            subject: 'Stick0ne Wallpaper',
            text: 'Save or apply your Stick0ne wallpaper',
          );
          return WallpaperResult(
            success: true,
            message: 'Wallpaper saved! Please select Set as Wallpaper from the options.',
            savedPath: file.path,
          );
        }
      }

      // iOS and other platforms:
      // iOS sandboxing requires saving to Photos or using UIActivityViewController (Share sheet)
      // which has the built-in "Use as Wallpaper" / "Save Image" option!
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'Stick0ne Wallpaper',
        text: 'Save image to Photos and set as Home or Lock screen wallpaper',
      );

      return WallpaperResult(
        success: true,
        message: 'Wallpaper ready! Tap "Save Image" or "Use as Wallpaper" in the sheet.',
        savedPath: file.path,
      );
    } catch (e) {
      debugPrint('Error applying wallpaper: $e');
      return WallpaperResult(
        success: false,
        message: 'Failed to apply wallpaper: $e',
      );
    }
  }
}
