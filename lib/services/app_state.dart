import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/notification_parser.dart';
import '../services/sync_service.dart';

/// 全局状态管理
class AppState extends ChangeNotifier {
  final DatabaseService _dbService;
  final NotificationService _notificationService;
  final NotificationParser _parser;
  final SyncService _syncService;

  List<Transaction> _transactions = [];
  double _monthlyExpense = 0;
  double _monthlyIncome = 0;
  Map<String, double> _categoryStats = {};
  bool _isListening = false;
  bool _isSyncing = false;
  bool _isBatteryOptimized = true;
  StreamSubscription? _notificationSubscription;

  AppState({
    required DatabaseService dbService,
    required NotificationService notificationService,
    required NotificationParser parser,
    required SyncService syncService,
  })  : _dbService = dbService,
        _notificationService = notificationService,
        _parser = parser,
        _syncService = syncService;

  // Getters
  List<Transaction> get transactions => _transactions;
  double get monthlyExpense => _monthlyExpense;
  double get monthlyIncome => _monthlyIncome;
  Map<String, double> get categoryStats => _categoryStats;
  bool get isListening => _isListening;
  bool get isSyncing => _isSyncing;
  bool get isBatteryOptimized => _isBatteryOptimized;

  /// 初始化：加载数据、处理待处理通知、开始实时监听
  Future<void> initialize() async {
    await loadTransactions();
    await loadMonthlyStats();
    await _checkBatteryOptimization();
    await _processPendingNotifications();
    await startListening();
  }

  /// 检查电池优化状态
  Future<void> _checkBatteryOptimization() async {
    _isBatteryOptimized =
        !await _notificationService.isBatteryOptimizationIgnored();
    notifyListeners();
  }

  /// 处理 App 不在前台时积累的待处理通知
  Future<void> _processPendingNotifications() async {
    try {
      final pendingList = await _notificationService.getPendingNotifications();
      debugPrint('发现 ${pendingList.length} 条待处理通知');

      int processed = 0;
      for (final data in pendingList) {
        final parsed = _parser.parse(data);
        if (parsed != null) {
          final transaction = parsed.toTransaction();
          await _dbService.insertTransaction(transaction);
          processed++;
        }
      }

      if (processed > 0) {
        debugPrint('已处理 $processed 条支付通知');
        await loadTransactions();
        await loadMonthlyStats();
      }
    } catch (e) {
      debugPrint('处理待处理通知出错: $e');
    }
  }

  /// 加载交易记录
  Future<void> loadTransactions() async {
    _transactions = await _dbService.getTransactions(limit: 100);
    notifyListeners();
  }

  /// 加载月度统计
  Future<void> loadMonthlyStats() async {
    _monthlyExpense = await _dbService.getMonthlyExpense();
    _monthlyIncome = await _dbService.getMonthlyIncome();
    _categoryStats = await _dbService.getCategoryStats(isExpense: true);
    notifyListeners();
  }

  /// 开始实时监听支付通知（App 在前台时）
  Future<void> startListening() async {
    _isListening = await _notificationService.isNotificationListenerEnabled();
    if (!_isListening) {
      notifyListeners();
      return;
    }

    _notificationSubscription?.cancel();
    _notificationSubscription =
        _notificationService.paymentNotificationStream.listen(
      _onPaymentNotification,
      onError: (e) {
        debugPrint('支付通知监听错误: $e');
      },
    );
    notifyListeners();
  }

  /// 处理实时支付通知
  Future<void> _onPaymentNotification(Map<String, dynamic> data) async {
    final parsed = _parser.parse(data);
    if (parsed == null) return;

    final transaction = parsed.toTransaction();
    await _dbService.insertTransaction(transaction);
    await loadTransactions();
    await loadMonthlyStats();
  }

  /// 手动添加交易记录
  Future<void> addTransaction(Transaction transaction) async {
    await _dbService.insertTransaction(transaction);
    await loadTransactions();
    await loadMonthlyStats();
  }

  /// 更新交易记录
  Future<void> updateTransaction(Transaction transaction) async {
    await _dbService.updateTransaction(transaction);
    await loadTransactions();
    await loadMonthlyStats();
  }

  /// 删除交易记录
  Future<void> deleteTransaction(String id) async {
    await _dbService.deleteTransaction(id);
    await _syncService.deleteFromCloud(id);
    await loadTransactions();
    await loadMonthlyStats();
  }

  /// 同步到云端
  Future<int> syncToCloud() async {
    _isSyncing = true;
    notifyListeners();

    final count = await _syncService.syncToCloud();

    _isSyncing = false;
    if (count > 0) {
      await loadTransactions();
    }
    notifyListeners();
    return count;
  }

  /// 从云端恢复
  Future<int> syncFromCloud() async {
    _isSyncing = true;
    notifyListeners();

    final count = await _syncService.syncFromCloud();

    _isSyncing = false;
    if (count > 0) {
      await loadTransactions();
      await loadMonthlyStats();
    }
    notifyListeners();
    return count;
  }

  /// 打开通知监听设置
  Future<void> openNotificationSettings() async {
    await _notificationService.openNotificationListenerSettings();
  }

  /// 请求关闭电池优化
  Future<void> requestIgnoreBatteryOptimization() async {
    await _notificationService.requestIgnoreBatteryOptimization();
  }

  /// 按日期范围获取交易记录
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return _dbService.getTransactionsByDateRange(start, end);
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
