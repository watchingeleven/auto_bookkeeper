import '../models/transaction.dart';
import 'package:uuid/uuid.dart';

/// 支付通知解析结果
class ParsedPayment {
  final double amount;
  final String merchant;
  final String category;
  final String paymentMethod;
  final bool isExpense;
  final String rawText;

  ParsedPayment({
    required this.amount,
    required this.merchant,
    required this.category,
    required this.paymentMethod,
    required this.isExpense,
    required this.rawText,
  });

  Transaction toTransaction() {
    return Transaction(
      id: const Uuid().v4(),
      amount: amount,
      merchant: merchant,
      category: category,
      paymentMethod: paymentMethod,
      rawNotification: rawText,
      createdAt: DateTime.now(),
      isExpense: isExpense,
    );
  }
}

/// 通知解析器 - 支持支付宝和微信支付
class NotificationParser {
  static const String _alipayPackage = 'com.eg.android.AlipayGphone';
  static const String _wechatPackage = 'com.tencent.mm';

  /// 解析通知数据，返回 ParsedPayment 或 null（非支付通知）
  ParsedPayment? parse(Map<String, dynamic> notificationData) {
    final packageName = notificationData['packageName'] as String? ?? '';
    final title = notificationData['title'] as String? ?? '';
    final text = notificationData['text'] as String? ?? '';
    final ticker = notificationData['ticker'] as String? ?? '';
    final rawText = '$title $text $ticker';

    if (packageName == _alipayPackage) {
      return _parseAlipay(title, text, ticker, rawText);
    } else if (packageName == _wechatPackage) {
      return _parseWechat(title, text, ticker, rawText);
    }
    return null;
  }

  /// 解析支付宝通知
  ParsedPayment? _parseAlipay(
      String title, String text, String ticker, String rawText) {
    // 支付宝支付成功通知格式示例:
    // title: "支付宝" 或 "付款成功"
    // text: "成功付款8.50元（美团外卖）" 或 "你已成功向xxx付款10.00元"
    //       "收到一笔转账 10.00元" 等

    double? amount;
    String merchant = '';
    bool isExpense = true;
    String category = '其他';

    // 检查是否为收入
    if (_containsAny(text, ['收到', '到账', '退款', '收款'])) {
      isExpense = false;
    }

    // 提取金额 - 多种格式匹配
    amount = _extractAmount(text) ?? _extractAmount(ticker);
    if (amount == null) return null;

    // 提取商家
    merchant = _extractAlipayMerchant(text);

    // 智能分类
    category = _inferCategory(merchant, text, isExpense);

    return ParsedPayment(
      amount: amount,
      merchant: merchant,
      category: category,
      paymentMethod: 'alipay',
      isExpense: isExpense,
      rawText: rawText,
    );
  }

  /// 解析微信支付通知
  ParsedPayment? _parseWechat(
      String title, String text, String ticker, String rawText) {
    // 微信支付成功通知格式示例:
    // title: "微信支付" 或 "微信支付凭证"
    // text: "支付￥8.50（美团外卖）" 或 "微信支付收款到账8.50元"
    //       "你收到xxx的转账 10.00元" 等

    // 非支付相关的微信通知直接跳过
    if (!_containsAny(title, ['微信支付', '支付', '转账', '红包', '收款'])) {
      // 检查 text 中是否包含支付关键词
      if (!_containsAny(text, ['支付', '付款', '收款', '转账', '红包', '元'])) {
        return null;
      }
    }

    double? amount;
    String merchant = '';
    bool isExpense = true;
    String category = '其他';

    // 检查是否为收入
    if (_containsAny(text, ['收到', '到账', '退款', '收款'])) {
      isExpense = false;
    }
    if (_containsAny(title, ['收款', '退款'])) {
      isExpense = false;
    }

    // 提取金额
    amount = _extractAmount(text) ?? _extractAmount(ticker);
    if (amount == null) return null;

    // 提取商家
    merchant = _extractWechatMerchant(text, title);

    // 智能分类
    category = _inferCategory(merchant, text, isExpense);

    return ParsedPayment(
      amount: amount,
      merchant: merchant,
      category: category,
      paymentMethod: 'wechat',
      isExpense: isExpense,
      rawText: rawText,
    );
  }

  /// 从文本中提取金额
  double? _extractAmount(String text) {
    // 匹配常见金额格式: ￥8.50, 8.50元, 付款8.50, ¥10.00
    final patterns = [
      RegExp(r'[￥¥]\s*(\d+\.?\d*)'),
      RegExp(r'(\d+\.?\d*)\s*元'),
      RegExp(r'付款\s*(\d+\.?\d*)'),
      RegExp(r'支付\s*(\d+\.?\d*)'),
      RegExp(r'收款\s*(\d+\.?\d*)'),
      RegExp(r'转账\s*(\d+\.?\d*)'),
      RegExp(r'金额\s*(\d+\.?\d*)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1);
        if (amountStr != null) {
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > 0) {
            return amount;
          }
        }
      }
    }
    return null;
  }

  /// 从支付宝通知中提取商家名称
  String _extractAlipayMerchant(String text) {
    // 格式: "成功付款8.50元（美团外卖）" -> 美团外卖
    final bracketPattern = RegExp(r'[（(](.+?)[）)]');
    final match = bracketPattern.firstMatch(text);
    if (match != null) {
      return match.group(1) ?? '';
    }

    // 格式: "向xxx付款" -> xxx
    final toPattern = RegExp(r'向(.+?)付款');
    final toMatch = toPattern.firstMatch(text);
    if (toMatch != null) {
      return toMatch.group(1) ?? '';
    }

    return '';
  }

  /// 从微信通知中提取商家名称
  String _extractWechatMerchant(String text, String title) {
    // 格式: "支付￥8.50（美团外卖）"
    final bracketPattern = RegExp(r'[（(](.+?)[）)]');
    final match = bracketPattern.firstMatch(text);
    if (match != null) {
      return match.group(1) ?? '';
    }

    // 格式: "你收到xxx的转账"
    final fromPattern = RegExp(r'(?:你收到|收到)(.+?)的转账');
    final fromMatch = fromPattern.firstMatch(text);
    if (fromMatch != null) {
      return fromMatch.group(1) ?? '';
    }

    // 格式: "xxx的转账"
    final fromPattern2 = RegExp(r'(.+?)的转账');
    final fromMatch2 = fromPattern2.firstMatch(text);
    if (fromMatch2 != null) {
      return fromMatch2.group(1) ?? '';
    }

    return '';
  }

  /// 根据商家名称和文本内容推断分类
  String _inferCategory(String merchant, String text, bool isExpense) {
    final combined = '$merchant $text'.toLowerCase();

    if (!isExpense) {
      if (_containsAny(combined, ['转账'])) return '转账';
      if (_containsAny(combined, ['红包'])) return '红包';
      if (_containsAny(combined, ['退款', '退'])) return '退款';
      return '其他';
    }

    // 餐饮
    if (_containsAny(combined, [
      '美团', '饿了么', '外卖', '餐', '食', '奶茶', '咖啡', '面包',
      '蛋糕', '火锅', '烧烤', '麦当劳', 'kfc', '肯德基', '星巴克',
      '瑞幸', '饮品', '小吃', '快餐', '便当', '早餐', '午餐', '晚餐',
      '超市', '菜', '水果',
    ])) return '餐饮';

    // 交通
    if (_containsAny(combined, [
      '滴滴', '打车', '出行', '地铁', '公交', '高铁', '火车',
      '机票', '飞机', '出租', '共享单车', '哈啰', '青桔', '美团单车',
      '加油', '停车', '高速', 'etc',
    ])) return '交通';

    // 购物
    if (_containsAny(combined, [
      '淘宝', '天猫', '京东', '拼多多', '购物', '商城', '专卖',
      '服装', '衣服', '鞋', '包', '数码', '电器', '手机',
    ])) return '购物';

    // 娱乐
    if (_containsAny(combined, [
      '电影', '游戏', '娱乐', '会员', 'vip', '视频', '音乐',
      '爱奇艺', '腾讯视频', '优酷', '网易云', 'bilibili', 'b站',
    ])) return '娱乐';

    // 医疗
    if (_containsAny(combined, [
      '医院', '药店', '药房', '诊所', '医疗', '体检', '挂号',
    ])) return '医疗';

    // 教育
    if (_containsAny(combined, [
      '学校', '培训', '课程', '教育', '书店', '学费', '考试',
    ])) return '教育';

    // 通讯
    if (_containsAny(combined, [
      '话费', '流量', '移动', '联通', '电信', '宽带',
    ])) return '通讯';

    // 住房
    if (_containsAny(combined, [
      '房租', '物业', '水费', '电费', '燃气', '暖气',
    ])) return '住房';

    // 日用
    if (_containsAny(combined, [
      '日用', '洗护', '纸巾', '清洁',
    ])) return '日用';

    // 转账
    if (_containsAny(combined, ['转账'])) return '转账';

    // 红包
    if (_containsAny(combined, ['红包'])) return '红包';

    return '其他';
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
}
