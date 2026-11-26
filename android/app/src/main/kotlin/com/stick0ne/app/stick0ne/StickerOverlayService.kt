package com.stick0ne.app.stick0ne

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.content.res.Configuration
import android.graphics.BitmapFactory
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import androidx.core.app.NotificationCompat
import java.io.File

class StickerOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayImageView: ImageView? = null

    companion object {
        const val ACTION_SHOW = "com.stick0ne.app.ACTION_SHOW_OVERLAY"
        const val ACTION_HIDE = "com.stick0ne.app.ACTION_HIDE_OVERLAY"
        const val EXTRA_IMAGE_PATH = "extra_image_path"
        const val CHANNEL_ID = "stick0ne_screen_sticker_channel"
        const val NOTIFICATION_ID = 1001
        const val FLAG_FILE_NAME = "overlay_active.flag"

        var isOverlayRunning: Boolean = false
            private set
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as? WindowManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val prefs = getSharedPreferences("stick0ne_overlay_prefs", Context.MODE_PRIVATE)
        when (intent?.action) {
            ACTION_SHOW -> {
                val imagePath = intent.getStringExtra(EXTRA_IMAGE_PATH)
                if (imagePath != null) {
                    prefs.edit().putString("last_image_path", imagePath).apply()
                    showOverlay(imagePath)
                }
            }
            ACTION_HIDE -> {
                prefs.edit().remove("last_image_path").apply()
                hideOverlay()
            }
            else -> {
                // Restored by system after process restart or task removal (START_STICKY)
                val flagFile = File(filesDir, FLAG_FILE_NAME)
                val lastPath = prefs.getString("last_image_path", null)
                if (flagFile.exists() && lastPath != null && File(lastPath).exists()) {
                    showOverlay(lastPath)
                } else if (!flagFile.exists()) {
                    stopSelf()
                }
            }
        }
        return START_STICKY
    }

    private fun showOverlay(imagePath: String) {
        try {
            val file = File(imagePath)
            if (!file.exists()) return

            val bitmap = BitmapFactory.decodeFile(imagePath) ?: return

            // Create persistent atomic flag file for cross-process synchronization
            try {
                File(filesDir, FLAG_FILE_NAME).createNewFile()
            } catch (_: Exception) {}

            // Start as foreground service with proper foreground service type for Android 14+
            val notification = buildForegroundNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification, 0)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }

            val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            // Overlay flags: touch-through, non-focusable, GPU accelerated, full-screen over apps
            val windowFlags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                layoutType,
                windowFlags,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = 0
                y = 0
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                }
            }

            if (overlayImageView == null) {
                overlayImageView = ImageView(this).apply {
                    scaleType = ImageView.ScaleType.FIT_XY
                    setImageBitmap(bitmap)
                }
                windowManager?.addView(overlayImageView, params)
            } else {
                overlayImageView?.setImageBitmap(bitmap)
                windowManager?.updateViewLayout(overlayImageView, params)
            }

            updateOverlayOrientation(resources.configuration.orientation)

            isOverlayRunning = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun hideOverlay() {
        try {
            try {
                File(filesDir, FLAG_FILE_NAME).delete()
            } catch (_: Exception) {}

            if (overlayImageView != null && windowManager != null) {
                if (overlayImageView?.isAttachedToWindow == true) {
                    windowManager?.removeViewImmediate(overlayImageView)
                }
                overlayImageView = null
            }
            isOverlayRunning = false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            stopSelf()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        // When the user swipes away the app from recent apps, maintain the overlay
        val flagFile = File(filesDir, FLAG_FILE_NAME)
        if (flagFile.exists()) {
            val prefs = getSharedPreferences("stick0ne_overlay_prefs", Context.MODE_PRIVATE)
            val lastPath = prefs.getString("last_image_path", null)
            if (lastPath != null && File(lastPath).exists()) {
                scheduleAutoRestart(lastPath)
            }
        }
    }

    private fun scheduleAutoRestart(imagePath: String) {
        try {
            val restartIntent = Intent(applicationContext, StickerOverlayService::class.java).apply {
                action = ACTION_SHOW
                putExtra(EXTRA_IMAGE_PATH, imagePath)
            }
            val pendingIntent = PendingIntent.getService(
                applicationContext,
                1002,
                restartIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager?.setAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    SystemClock.elapsedRealtime() + 500,
                    pendingIntent
                )
            } else {
                alarmManager?.set(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    SystemClock.elapsedRealtime() + 500,
                    pendingIntent
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Stick0ne Screen Sticker",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows notification when stickers are stuck on your screen"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun buildForegroundNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Stick0ne • Stuck on Screen")
            .setContentText("Stickers are stuck on your screen. Tap to edit in Stick0ne.")
            .setSmallIcon(android.R.drawable.ic_menu_crop)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        updateOverlayOrientation(newConfig.orientation)
    }

    private fun updateOverlayOrientation(orientation: Int) {
        if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
            // When the screen changes to horizontal (landscape), do not make the sticker horizontal or distort it
            overlayImageView?.visibility = View.GONE
        } else {
            overlayImageView?.visibility = View.VISIBLE
        }
    }

    override fun onDestroy() {
        val flagFile = File(filesDir, FLAG_FILE_NAME)
        if (flagFile.exists()) {
            // Destroyed unexpectedly by OS (e.g. low memory) while user wanted overlay active.
            val prefs = getSharedPreferences("stick0ne_overlay_prefs", Context.MODE_PRIVATE)
            val lastPath = prefs.getString("last_image_path", null)
            if (lastPath != null && File(lastPath).exists()) {
                scheduleAutoRestart(lastPath)
            }
        } else {
            // User explicitly hid overlay: clean up view
            if (overlayImageView != null && windowManager != null) {
                try {
                    if (overlayImageView?.isAttachedToWindow == true) {
                        windowManager?.removeViewImmediate(overlayImageView)
                    }
                } catch (_: Exception) {}
                overlayImageView = null
            }
        }
        isOverlayRunning = false
        super.onDestroy()
    }
}
