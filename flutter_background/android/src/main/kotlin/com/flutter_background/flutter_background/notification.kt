package com.flutter_background.flutter_background

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import android.app.NotificationManager;
import android.app.NotificationChannel;
import android.net.Uri;
import android.app.PendingIntent;
import android.media.AudioAttributes;
import android.content.ContentResolver;
import android.graphics.BitmapFactory;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import android.util.Log;
import android.R


class Notification: FlutterActivity(){
    private val NOTIFICATION_ID = 101

    public fun createNotificationChannel(appContext : Context ,mapData: HashMap<String,String>) {
        if (VERSION.SDK_INT >= VERSION_CODES.O) {
            val id = mapData["id"]
            val name = mapData["name"]
            val descriptionText = mapData["description"]
            val importance = NotificationManager.IMPORTANCE_HIGH
            val mChannel = NotificationChannel(id, name, importance)
            mChannel.description = descriptionText

            val att = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
            .build();

            val notificationManager = appContext.getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(mChannel)

            notification(appContext,mChannel)
        }
    }
    public fun notification(appContext:Context,mapData: NotificationChannel){
        val intent = Intent(appContext,FlutterActivity::class.java).apply{
            flags= Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }

        val pendingIntent = PendingIntent.getActivity(appContext,0,intent,0)
        val resID = appContext.resources.getIdentifier("app_icon", "drawable", appContext.packageName)

        val builder = NotificationCompat.Builder(appContext, mapData.id).apply {
            if(resID !=0){
                setSmallIcon(appContext.applicationInfo.icon)
                setContentTitle(mapData.name)
                setContentText(mapData.description)
                setContentIntent(pendingIntent)
                setPriority(NotificationCompat.PRIORITY_DEFAULT)
            } else {
                setSmallIcon(resID)
                setContentTitle(mapData.name)
                setContentText(mapData.description)
                setContentIntent(pendingIntent)
                setPriority(NotificationCompat.PRIORITY_DEFAULT)
            }
        }
        // displaying the notification with NotificationManagerCompat.
        with(NotificationManagerCompat.from(appContext)) {
            notify(NOTIFICATION_ID, builder.build())
        }
    }
}