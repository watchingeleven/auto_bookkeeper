import 'package:flutter_test/flutter_test.dart';
import 'package:auto_bookkeeper/services/notification_parser.dart';

void main() {
  late NotificationParser parser;

  setUp(() {
    parser = NotificationParser();
  });

  group('支付宝通知解析', () {
    test('解析支付宝付款通知 - 括号格式', () {
      final result = parser.parse({
        'packageName': 'com.eg.android.AlipayGphone',
        'title': '支付宝',
        'text': '成功付款8.50元（美团外卖）',
        'ticker': '',
        'timestamp': 1710000000000,
      });

      expect(result, isNotNull);
      expect(result!.amount, 8.50);
      expect(result.merchant, '美团外卖');
      expect(result.paymentMethod, 'alipay');
      expect(result.isExpense, true);
      expect(result.category, '餐饮');
    });

    test('解析支付宝付款通知 - 向xxx付款格式', () {
      final result = parser.parse({
        'packageName': 'com.eg.android.AlipayGphone',
        'title': '付款成功',
        'text': '你已成功向星巴克付款35.00元',
        'ticker': '',
        'timestamp': 1710000000000,
      });

      expect(result, isNotNull);
      expect(result!.amount, 35.00);
      expect(result.merchant, '星巴克');
      expect(result.isExpense, true);
      expect(result.category, '餐饮');
    });

    test('解析支付宝收款通知', () {
      final result = parser.parse({
        'packageName': 'com.eg.android.AlipayGphone',
        'title': '支付宝',
        'text': '收到一笔转账 100.00元',
        'ticker': '',
        'timestamp': 1710000000000,
      });

      expect(result, isNotNull);
      expect(result!.amount, 100.00);
      expect(result.isExpense, false);
      expect(result.category, '转账');
    });

    test('解析支付宝交通类消费', () {
      final result = parser.parse({
        'packageName': 'com.eg.android.AlipayGphone',
        'title': '支付宝',
        'text': '成功付款15.80元（滴滴出行）',
        'ticker': '',
        'timestamp': 1710000000000,
      });

      expect(result, isNotNull);
      expect(result!.amount, 15.80);
      expect(result.merchant, '滴滴出行');
      expect(result.category, '交通');
    });
  });

  group('微信支付通知解析', () {
    test('解析微信支付通知 - 括号格式', () {
      final result = parser.parse({
        'packageName': 'com.tencent.mm',
        'title': '微信支付',
        'text': '支付￥25.00（肯德基）',
        'ticker': '',
        'timestamp': 1710000000000,
      });

      expect(result, isNotNull);
      expect(result!.amount, 25.00);
      expect(result.merchant, '肯德基');
      expect(result.paymentMethod, 'wechat');
      expect(result.isExpense, true);
      expect(result.category, '餐饮');
    });

    test('解析微信收款通知', () {
      final result = parser.parse({
        'packageName': 'com.tencent.mm',
        'title': '微信支付收款',
        'text': '微信支付收款到账50.00元',
        'ticker': '',
        'timestamp': 1710000000000,
      });

      expect(result, isNotNull);
      expect(result!.amount, 50.00);
      expect(result.isExpense, false);
    });

    test('解析微信转账通知', () {
      final result = parser.parse({
        'packageName': 'com.tencent.mm',
        'title': '微信支付',
        'text': '你收到张三的转账 200.00元',
        'ticker': '',
        'timestamp': 1710000000000,
      });

      expect(result, isNotNull);
      expect(result!.amount, 200.00);
      expect(result.isExpense, false);
      expect(result.merchant, '张三');
    });

    test('忽略非支付微信通知', () {
      final result = parser.parse({
        'packageName': 'com.tencent.mm',
        'title': '张三',
        'text': '你好，明天见',
        'ticker': '',
        'timestamp': 1710000000000,
      });

      expect(result, isNull);
    });
  });

  group('金额提取测试', () {
    test('解析带￥符号的金额', () {
      final result = parser.parse({
        'packageName': 'com.tencent.mm',
        'title': '微信支付',
        'text': '支付￥99.90（京东商城）',
        'ticker': '',
        'timestamp': 1710000000000,
      });

      expect(result, isNotNull);
      expect(result!.amount, 99.90);
    });

    test('解析整数金额', () {
      final result = parser.parse({
        'packageName': 'com.eg.android.AlipayGphone',
        'title': '支付宝',
        'text': '成功付款100元（淘宝）',
        'ticker': '',
        'timestamp': 1710000000000,
      });

      expect(result, isNotNull);
      expect(result!.amount, 100.0);
    });
  });

  group('分类推断测试', () {
    test('餐饮分类', () {
      final result = parser.parse({
        'packageName': 'com.eg.android.AlipayGphone',
        'title': '支付宝',
        'text': '成功付款28.00元（饿了么外卖）',
        'ticker': '',
        'timestamp': 1710000000000,
      });

      expect(result, isNotNull);
      expect(result!.category, '餐饮');
    });

    test('购物分类', () {
      final result = parser.parse({
        'packageName': 'com.tencent.mm',
        'title': '微信支付',
        'text': '支付￥299.00（拼多多）',
        'ticker': '',
        'timestamp': 1710000000000,
      });

      expect(result, isNotNull);
      expect(result!.category, '购物');
    });

    test('娱乐分类', () {
      final result = parser.parse({
        'packageName': 'com.eg.android.AlipayGphone',
        'title': '支付宝',
        'text': '成功付款30.00元（爱奇艺会员）',
        'ticker': '',
        'timestamp': 1710000000000,
      });

      expect(result, isNotNull);
      expect(result!.category, '娱乐');
    });
  });
}
