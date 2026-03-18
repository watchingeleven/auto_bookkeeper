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

  /// 拉取 App 不在前台时积累的待处理通知
  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    try {
      final result = await _methodChannel.invokeMethod('getPendingNotifications');
      if (result == null) return [];
      return (result as List).map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();
    } on PlatformException {
      return [];
    }
  }

  /// 请求忽略电池优化（华为/荣耀必需）
  Future<void> requestIgnoreBatteryOptimization() async {
    try {
      await _methodChannel.invokeMethod('requestIgnoreBatteryOptimization');
    } on PlatformException {
      // ignore
    }
  }

  /// 检查是否已忽略电池优化
  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 实时监听支付通知（App 在前台时）
  Stream<Map<String, dynamic>> get paymentNotificationStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event as Map);
    });
  }
}
