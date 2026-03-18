package com.example.auto_bookkeeper

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject

/**
 * 支付通知监听服务
 *
 * 核心改进：收到通知后直接写入 SharedPreferences，
 * 不依赖 Activity 广播，即使 App 在后台也能工作。
 */
class PaymentNotificationService : NotificationListenerService() {

    companion object {
        private const val TAG = "PaymentNotifService"

        const val ALIPAY_PACKAGE = "com.eg.android.AlipayGphone"
        const val WECHAT_PACKAGE = "com.tencent.mm"
        val PAYMENT_PACKAGES = setOf(ALIPAY_PACKAGE, WECHAT_PACKAGE)

        const val PREFS_NAME = "payment_notifications"
        const val KEY_PENDING = "pending_notifications"

        const val ACTION_PAYMENT_NOTIFICATION = "com.example.auto_bookkeeper.PAYMENT_NOTIFICATION"
        const val EXTRA_PACKAGE = "package_name"
        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"
        const val EXTRA_SUBTEXT = "subtext"
        const val EXTRA_TICKER = "ticker"
        const val EXTRA_TIMESTAMP = "timestamp"

        private const val CHANNEL_ID = "payment_listener_channel"
        private const val FOREGROUND_NOTIFICATION_ID = 1001

        /**
         * 从 SharedPreferences 读取并清空待处理通知
         */
        fun consumePendingNotifications(context: Context): List<Map<String, Any>> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonStr = prefs.getString(KEY_PENDING, "[]") ?: "[]"
            val result = mutableListOf<Map<String, Any>>()

            try {
                val array = JSONArray(jsonStr)
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    result.add(mapOf(
                        "packageName" to obj.optString("packageName", ""),
                        "title" to obj.optString("title", ""),
                        "text" to obj.optString("text", ""),
                        "subText" to obj.optString("subText", ""),
                        "ticker" to obj.optString("ticker", ""),
                        "timestamp" to obj.optLong("timestamp", 0)
                    ))
                }
            } catch (e: Exception) {
                Log.e(TAG, "解析待处理通知失败", e)
            }

            // 清空
            prefs.edit().putString(KEY_PENDING, "[]").apply()
            return result
        }
    }

    override fun onCreate() {
        super.onCreate()
        startForegroundServiceNotification()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return

        val packageName = sbn.packageName
        if (packageName !in PAYMENT_PACKAGES) return

        val notification = sbn.notification ?: return
        val extras: Bundle = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""
        val ticker = sbn.notification.tickerText?.toString() ?: ""
        val timestamp = sbn.postTime

        Log.d(TAG, "收到支付通知: pkg=$packageName, title=$title, text=$text")

        // 1. 写入 SharedPreferences（可靠存储，不依赖 Activity）
        saveToPending(packageName, title, text, subText, ticker, timestamp)

        // 2. 同时广播（如果 Activity 在前台可以实时收到）
        val intent = Intent(ACTION_PAYMENT_NOTIFICATION).apply {
            putExtra(EXTRA_PACKAGE, packageName)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_TEXT, text)
            putExtra(EXTRA_SUBTEXT, subText)
            putExtra(EXTRA_TICKER, ticker)
            putExtra(EXTRA_TIMESTAMP, timestamp)
            setPackage(applicationContext.packageName)
        }
        sendBroadcast(intent)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {}

    /**
     * 将通知数据追加到 SharedPreferences 的 JSON 数组中
     */
    private fun saveToPending(
        packageName: String, title: String, text: String,
        subText: String, ticker: String, timestamp: Long
    ) {
        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonStr = prefs.getString(KEY_PENDING, "[]") ?: "[]"
            val array = JSONArray(jsonStr)

            val obj = JSONObject().apply {
                put("packageName", packageName)
                put("title", title)
                put("text", text)
                put("subText", subText)
                put("ticker", ticker)
                put("timestamp", timestamp)
            }
            array.put(obj)

            prefs.edit().putString(KEY_PENDING, array.toString()).apply()
            Log.d(TAG, "已保存到待处理队列，当前 ${array.length()} 条")
        } catch (e: Exception) {
            Log.e(TAG, "保存通知失败", e)
        }
    }

    /**
     * 前台服务通知 - 防止系统杀死后台服务（华为/荣耀必需）
     */
    private fun startForegroundServiceNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "支付监听服务",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "保持自动记账服务在后台运行"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("自动记账运行中")
            .setContentText("正在监听支付通知")
            .setSmallIcon(android.R.drawable.ic_menu_manage)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        try {
            startForeground(FOREGROUND_NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.w(TAG, "启动前台服务失败（低版本可忽略）", e)
        }
    }
}
