package com.portfolio.finance_hub

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "wealth_os/native_notifications"
    private val CHANNEL_ID = "wealth_os_core_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeNativeChannel" -> {
                    createNotificationChannelBlueprints()
                    result.success(true)
                }
                "dispatchSystemPush" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val title = call.argument<String>("title") ?: "Alert"
                    val body = call.argument<String>("body") ?: ""
                    triggerNativeStatusBarAlert(id, title, body)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannelBlueprints() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "System Financial Triggers"
            val descriptionText = "Reactive financial matrix alerts"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun triggerNativeStatusBarAlert(id: Int, title: String, body: String) {
        val context = applicationContext
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val systemIcon = android.R.drawable.stat_notify_chat

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(systemIcon)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)

        notificationManager.notify(id, builder.build())
    }
}