package com.example.myapp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        println("🔔 New FCM Token: $token")
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        println("🔔 FCM Message received in Service!")
        println("🔔 From: ${remoteMessage.from}")
        println("🔔 Data: ${remoteMessage.data}")
        println("🔔 Notification: ${remoteMessage.notification}")

        // Check if message contains a notification payload
        remoteMessage.notification?.let { notification ->
            sendNotification(
                notification.title ?: "Akhdem Li",
                notification.body ?: "New notification",
                remoteMessage.data
            )
        }

        // Also handle data-only messages
        if (remoteMessage.data.isNotEmpty() && remoteMessage.notification == null) {
            val title = remoteMessage.data["title"] ?: "Akhdem Li"
            val body = remoteMessage.data["body"] ?: "New message"
            sendNotification(title, body, remoteMessage.data)
        }
    }

    private fun sendNotification(title: String, messageBody: String, data: Map<String, String>) {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("notification_data", data.toString())
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )

        val channelId = "high_importance_channel"
        val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        
        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Change to your custom icon
            .setContentTitle(title)
            .setContentText(messageBody)
            .setAutoCancel(true)
            .setSound(defaultSoundUri)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVibrate(longArrayOf(1000, 1000, 1000, 1000))

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create notification channel for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "High Importance Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "This channel is used for important notifications"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 1000, 500)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Generate unique ID for each notification
        val notificationId = System.currentTimeMillis().toInt()
        notificationManager.notify(notificationId, notificationBuilder.build())
        
        println("🔔 Notification sent with ID: $notificationId")
    }
}