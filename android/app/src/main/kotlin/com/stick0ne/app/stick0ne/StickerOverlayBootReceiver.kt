package com.stick0ne.app.stick0ne

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import java.io.File

class StickerOverlayBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val receivedAction = intent?.action
        if (receivedAction == Intent.ACTION_BOOT_COMPLETED ||
            receivedAction == Intent.ACTION_MY_PACKAGE_REPLACED ||
            receivedAction == "android.intent.action.QUICKBOOT_POWERON" ||
            receivedAction == "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            val flagFile = File(context.filesDir, StickerOverlayService.FLAG_FILE_NAME)
            val prefs = context.getSharedPreferences("stick0ne_overlay_prefs", Context.MODE_PRIVATE)
            val lastPath = prefs.getString("last_image_path", null)

            if (flagFile.exists() && lastPath != null && File(lastPath).exists()) {
                val serviceIntent = Intent(context, StickerOverlayService::class.java).apply {
                    setAction(StickerOverlayService.ACTION_SHOW)
                    putExtra(StickerOverlayService.EXTRA_IMAGE_PATH, lastPath)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }
}
