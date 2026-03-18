/// 交易记录数据模型
class Transaction {
  final String id;
  final double amount;
  final String merchant;
  final String category;
  final String paymentMethod; // 'alipay' | 'wechat'
  final String rawNotification;
  final DateTime createdAt;
  final bool isExpense; // true=支出, false=收入
  final String? note;
  final bool synced; // 是否已同步到云端

  Transaction({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.category,
    required this.paymentMethod,
    required this.rawNotification,
    required this.createdAt,
    this.isExpense = true,
    this.note,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'category': category,
      'payment_method': paymentMethod,
      'raw_notification': rawNotification,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_expense': isExpense ? 1 : 0,
      'note': note,
      'synced': synced ? 1 : 0,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      merchant: map['merchant'] as String,
      category: map['category'] as String,
      paymentMethod: map['payment_method'] as String,
      rawNotification: map['raw_notification'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isExpense: (map['is_expense'] as int) == 1,
      note: map['note'] as String?,
      synced: (map['synced'] as int) == 1,
    );
  }

  Transaction copyWith({
    String? id,
    double? amount,
    String? merchant,
    String? category,
    String? paymentMethod,
    String? rawNotification,
    DateTime? createdAt,
    bool? isExpense,
    String? note,
    bool? synced,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      rawNotification: rawNotification ?? this.rawNotification,
      createdAt: createdAt ?? this.createdAt,
      isExpense: isExpense ?? this.isExpense,
      note: note ?? this.note,
      synced: synced ?? this.synced,
    );
  }

  /// 转换为 Firestore 文档格式
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'category': category,
      'paymentMethod': paymentMethod,
      'rawNotification': rawNotification,
      'createdAt': createdAt.toIso8601String(),
      'isExpense': isExpense,
      'note': note,
    };
  }

  factory Transaction.fromFirestore(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      merchant: map['merchant'] as String,
      category: map['category'] as String,
      paymentMethod: map['paymentMethod'] as String,
      rawNotification: map['rawNotification'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isExpense: map['isExpense'] as bool,
      note: map['note'] as String?,
      synced: true,
    );
  }
}
