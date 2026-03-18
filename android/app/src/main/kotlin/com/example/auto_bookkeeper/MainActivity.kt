package com.example.auto_bookkeeper

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val METHOD_CHANNEL = "com.example.auto_bookkeeper/notification"
        private const val EVENT_CHANNEL = "com.example.auto_bookkeeper/payment_events"
    }

    private var eventSink: EventChannel.EventSink? = null
    private var paymentReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel: 用于检查权限和跳转设置
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationListenerEnabled" -> {
                    result.success(isNotificationListenerEnabled())
                }
                "openNotificationListenerSettings" -> {
                    openNotificationListenerSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // EventChannel: 用于实时推送支付通知到 Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerPaymentReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    unregisterPaymentReceiver()
                }
            }
        )
    }

    /**
     * 检查通知监听权限是否已开启
     */
    private fun isNotificationListenerEnabled(): Boolean {
        val enabledListeners = NotificationManagerCompat.getEnabledListenerPackages(this)
        return enabledListeners.contains(packageName)
    }

    /**
     * 跳转到通知监听设置页面
     */
    private fun openNotificationListenerSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }

    /**
     * 注册广播接收器，接收来自 PaymentNotificationService 的支付通知
     */
    private fun registerPaymentReceiver() {
        if (paymentReceiver != null) return

        paymentReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                intent ?: return
                val data = mapOf(
                    "packageName" to (intent.getStringExtra(PaymentNotificationService.EXTRA_PACKAGE) ?: ""),
                    "title" to (intent.getStringExtra(PaymentNotificationService.EXTRA_TITLE) ?: ""),
                    "text" to (intent.getStringExtra(PaymentNotificationService.EXTRA_TEXT) ?: ""),
                    "subText" to (intent.getStringExtra(PaymentNotificationService.EXTRA_SUBTEXT) ?: ""),
                    "ticker" to (intent.getStringExtra(PaymentNotificationService.EXTRA_TICKER) ?: ""),
                    "timestamp" to intent.getLongExtra(PaymentNotificationService.EXTRA_TIMESTAMP, 0)
                )
                eventSink?.success(data)
            }
        }

        val filter = IntentFilter(PaymentNotificationService.ACTION_PAYMENT_NOTIFICATION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(paymentReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(paymentReceiver, filter)
        }
    }

    private fun unregisterPaymentReceiver() {
        paymentReceiver?.let {
            unregisterReceiver(it)
            paymentReceiver = null
        }
    }

    override fun onDestroy() {
        unregisterPaymentReceiver()
        super.onDestroy()
    }
}
