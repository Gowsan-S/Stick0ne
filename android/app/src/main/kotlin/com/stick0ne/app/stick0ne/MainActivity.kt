package com.stick0ne.app.stick0ne

import android.app.WallpaperManager
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val WALLPAPER_CHANNEL = "com.stick0ne.app/wallpaper"
    private val OVERLAY_CHANNEL = "com.stick0ne.app/overlay"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Wallpaper Channel (Feature 5: Wallpaper Export fallback)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WALLPAPER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setWallpaper" -> {
                    val bytes = call.argument<ByteArray>("imageBytes")
                    val location = call.argument<Int>("location") ?: 3 // 1: Home, 2: Lock, 3: Both

                    if (bytes == null) {
                        result.error("INVALID_ARGUMENT", "Image bytes cannot be null", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                            if (bitmap == null) {
                                runOnUiThread {
                                    result.error("DECODE_ERROR", "Failed to decode bitmap from bytes", null)
                                }
                                return@Thread
                            }

                            val wallpaperManager = WallpaperManager.getInstance(applicationContext)

                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                val flag = when (location) {
                                    1 -> WallpaperManager.FLAG_SYSTEM
                                    2 -> WallpaperManager.FLAG_LOCK
                                    else -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
                                }
                                wallpaperManager.setBitmap(bitmap, null, true, flag)
                            } else {
                                wallpaperManager.setBitmap(bitmap)
                            }

                            runOnUiThread {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("SET_WALLPAPER_ERROR", e.localizedMessage, null)
                            }
                        }
                    }.start()
                }
                "isLockScreenSupported" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 2. Screen Overlay Channel (Feature 3, 4, 5: Stick to Screen over launcher & apps)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "canDrawOverlays" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            ).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            val fallbackIntent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(fallbackIntent)
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "isXiaomiDevice" -> {
                    val manufacturer = Build.MANUFACTURER.lowercase()
                    result.success(
                        manufacturer.contains("xiaomi") ||
                        manufacturer.contains("redmi") ||
                        manufacturer.contains("poco")
                    )
                }
                "openMiuiPermissionSettings" -> {
                    try {
                        val intent = Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                            setClassName(
                                "com.miui.securitycenter",
                                "com.miui.permcenter.permissions.PermissionsEditorActivity"
                            )
                            putExtra("extra_pkgname", packageName)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("SETTINGS_ERROR", e2.localizedMessage, null)
                        }
                    }
                }
                "showOverlay" -> {
                    val imagePath = call.argument<String>("imagePath")
                    if (imagePath.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENT", "imagePath cannot be null or empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val intent = Intent(this, StickerOverlayService::class.java).apply {
                            action = StickerOverlayService.ACTION_SHOW
                            putExtra(StickerOverlayService.EXTRA_IMAGE_PATH, imagePath)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OVERLAY_START_FAILED", e.localizedMessage, null)
                    }
                }
                "hideOverlay" -> {
                    try {
                        val flagFile = File(filesDir, StickerOverlayService.FLAG_FILE_NAME)
                        if (flagFile.exists()) {
                            flagFile.delete()
                        }
                        val intent = Intent(this, StickerOverlayService::class.java).apply {
                            action = StickerOverlayService.ACTION_HIDE
                        }
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OVERLAY_STOP_FAILED", e.localizedMessage, null)
                    }
                }
                "isOverlayActive" -> {
                    val flagFile = File(filesDir, StickerOverlayService.FLAG_FILE_NAME)
                    result.success(flagFile.exists())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
