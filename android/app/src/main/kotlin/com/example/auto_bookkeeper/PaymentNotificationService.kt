package com.example.auto_bookkeeper

import android.app.Notification
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * 支付通知监听服务
 * 监听支付宝和微信支付的通知，提取支付信息
 */
class PaymentNotificationService : NotificationListenerService() {

    companion object {
        private const val TAG = "PaymentNotifService"

        // 支付宝包名
        const val ALIPAY_PACKAGE = "com.eg.android.AlipayGphone"
        // 微信包名
        const val WECHAT_PACKAGE = "com.tencent.mm"

        // 目标包名集合
        val PAYMENT_PACKAGES = setOf(ALIPAY_PACKAGE, WECHAT_PACKAGE)

        // 广播 Action
        const val ACTION_PAYMENT_NOTIFICATION = "com.example.auto_bookkeeper.PAYMENT_NOTIFICATION"
        const val EXTRA_PACKAGE = "package_name"
        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"
        const val EXTRA_SUBTEXT = "subtext"
        const val EXTRA_TICKER = "ticker"
        const val EXTRA_TIMESTAMP = "timestamp"
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

        Log.d(TAG, "收到支付通知: pkg=$packageName, title=$title, text=$text, sub=$subText")

        // 发送本地广播到 Flutter 侧
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

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // 不需要处理
    }
}
