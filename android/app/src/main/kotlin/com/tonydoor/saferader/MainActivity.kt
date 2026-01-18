package com.tonydoor.saferader

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // ✅ CRITICAL: Create the channel that BackgroundService expects
            val backgroundServiceChannel = NotificationChannel(
                "LocationSocketSharingChannel",  // MUST match your service config
                "Location Sharing Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps location sharing active when app is in background"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }

            // High importance channel for notifications
            val highChannel = NotificationChannel(
                "high_importance_channel",
                "Important Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Important app notifications"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }

            // Low importance channel
            val lowChannel = NotificationChannel(
                "low_importance_channel",
                "Background Updates",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background app updates"
                enableLights(false)
                enableVibration(false)
                setShowBadge(false)
            }

            // Create all channels
            notificationManager.createNotificationChannel(backgroundServiceChannel)
            notificationManager.createNotificationChannel(highChannel)
            notificationManager.createNotificationChannel(lowChannel)
        }
    }
}