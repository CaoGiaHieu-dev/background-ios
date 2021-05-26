package com.flutter_background.flutter_background

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat

object BackgroundNotification {
    const val NOTIFICATION_ID_BACKGROUND_SERVICE = 1

    private const val CHANNEL_ID_BACKGROUND_SERVICE = "background_service"

    fun createNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID_BACKGROUND_SERVICE,
                "Background Service",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    fun buildForegroundNotification(context: Context): Notification {
        val resID = context.resources.getIdentifier("app_icon", "drawable", context.packageName)
        if(resID !=0){
            return NotificationCompat
            .Builder(context, CHANNEL_ID_BACKGROUND_SERVICE)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle("Background Service")
            .setContentText("Keeps app process on foreground.")
            .build()
               
        } else {
            return NotificationCompat
            .Builder(context, CHANNEL_ID_BACKGROUND_SERVICE)
            .setSmallIcon(resID)
            .setContentTitle("Background Service")
            .setContentText("Keeps app process on foreground.")
            .build()
        }
    }
}