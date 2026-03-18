package com.example.auto_bookkeeper

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationListenerEnabled" -> {
                    result.success(isNotificationListenerEnabled())
                }
                "openNotificationListenerSettings" -> {
                    openNotificationListenerSettings()
                    result.success(true)
                }
                "getPendingNotifications" -> {
                    // 从 SharedPreferences 拉取待处理通知
                    val pending = PaymentNotificationService.consumePendingNotifications(this)
                    result.success(pending)
                }
                "requestIgnoreBatteryOptimization" -> {
                    requestIgnoreBatteryOptimization()
                    result.success(true)
                }
                "isBatteryOptimizationIgnored" -> {
                    result.success(isBatteryOptimizationIgnored())
                }
                else -> result.notImplemented()
            }
        }

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

    private fun isNotificationListenerEnabled(): Boolean {
        val enabledListeners = NotificationManagerCompat.getEnabledListenerPackages(this)
        return enabledListeners.contains(packageName)
    }

    private fun openNotificationListenerSettings() {
        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
    }

    /**
     * 请求忽略电池优化（华为/荣耀手机必需）
     */
    private fun requestIgnoreBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivity(intent)
            }
        }
    }

    private fun isBatteryOptimizationIgnored(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            return pm.isIgnoringBatteryOptimizations(packageName)
        }
        return true
    }

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
