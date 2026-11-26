import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OverlayResult {
  final bool success;
  final String message;
  final bool permissionNeeded;

  OverlayResult({
    required this.success,
    required this.message,
    this.permissionNeeded = false,
  });
}

class ScreenOverlayService {
  static const MethodChannel _channel = MethodChannel('com.stick0ne.app/overlay');

  /// Check whether 'Appear on top' / SYSTEM_ALERT_WINDOW permission is granted.
  Future<bool> canDrawOverlays() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return false;

    try {
      final bool? result = await _channel.invokeMethod<bool>('canDrawOverlays');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking overlay permission: ${e.message}');
      return false;
    }
  }

  /// Open Android system settings to grant 'Appear on top' permission.
  Future<bool> requestOverlayPermission() async {
    if (kIsWeb || !Platform.isAndroid) return false;

    try {
      final bool? result =
          await _channel.invokeMethod<bool>('requestOverlayPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error requesting overlay permission: ${e.message}');
      return false;
    }
  }

  /// Check whether the current device is manufactured by Xiaomi/Redmi/Poco (MIUI/HyperOS).
  Future<bool> isXiaomiDevice() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final bool? result = await _channel.invokeMethod<bool>('isXiaomiDevice');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open Xiaomi MIUI/HyperOS "Other permissions" to enable "Display pop-up windows while running in the background".
  Future<bool> openMiuiPermissionSettings() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('openMiuiPermissionSettings');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if the screen sticker overlay service is currently running.
  Future<bool> isOverlayActive() async {
    if (kIsWeb || !Platform.isAndroid) return false;

    try {
      final bool? result = await _channel.invokeMethod<bool>('isOverlayActive');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking overlay active: ${e.message}');
      return false;
    }
  }

  /// Sticks the rendered transparent stickers directly on top of the phone screen display.
  /// Touches pass through to launcher & apps underneath (Feature 4: unmovable outside app).
  Future<OverlayResult> stickToScreen(Uint8List imageBytes) async {
    if (kIsWeb) {
      return OverlayResult(
        success: false,
        message: 'Screen overlays are only supported on physical mobile devices.',
      );
    }

    if (!Platform.isAndroid) {
      // iOS sandboxing prevents apps from drawing floating windows outside sandbox
      return OverlayResult(
        success: false,
        message:
            'Apple iOS sandboxing restricts floating screen overlays. Use the Stick0ne Widget or Wallpaper Mode to display your stickers.',
      );
    }

    try {
      final hasPermission = await canDrawOverlays();
      if (!hasPermission) {
        return OverlayResult(
          success: false,
          permissionNeeded: true,
          message: 'Permission required: Enable "Appear on top" in Android settings.',
        );
      }

      // 1. Save image to permanent app documents directory so it is never purged when switching apps
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/active_screen_sticker.png');
      await file.writeAsBytes(imageBytes, flush: true);

      // 2. Invoke native service to attach overlay to WindowManager
      final bool? result = await _channel.invokeMethod<bool>('showOverlay', {
        'imagePath': file.path,
      });

      if (result == true) {
        return OverlayResult(
          success: true,
          message: 'Sticker successfully stuck to your screen! Reopen Stick0ne anytime to edit or remove.',
        );
      } else {
        return OverlayResult(
          success: false,
          message: 'Failed to launch screen sticker overlay.',
        );
      }
    } on PlatformException catch (e) {
      return OverlayResult(
        success: false,
        message: 'Overlay error: ${e.message}',
      );
    }
  }

  /// Removes the floating sticker from the phone screen display.
  Future<bool> removeFromScreen() async {
    if (kIsWeb || !Platform.isAndroid) return false;

    try {
      final bool? result = await _channel.invokeMethod<bool>('hideOverlay');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error removing overlay: ${e.message}');
      return false;
    }
  }
}
