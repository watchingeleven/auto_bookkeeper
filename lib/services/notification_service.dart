import 'package:flutter/services.dart';

/// 与 Android 原生通知监听服务通信的平台通道
class NotificationService {
  static const _methodChannel =
      MethodChannel('com.example.auto_bookkeeper/notification');
  static const _eventChannel =
      EventChannel('com.example.auto_bookkeeper/payment_events');

  /// 检查通知监听权限是否已开启
  Future<bool> isNotificationListenerEnabled() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('isNotificationListenerEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 打开通知监听设置页面
  Future<void> openNotificationListenerSettings() async {
    try {
      await _methodChannel.invokeMethod('openNotificationListenerSettings');
    } on PlatformException {
      // ignore
    }
  }

  /// 监听支付通知事件流
  Stream<Map<String, dynamic>> get paymentNotificationStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event as Map);
    });
  }
}
