import 'package:flutter/material.dart';

/// 交易分类模型
class Category {
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.name,
    required this.icon,
    required this.color,
  });

  /// 预定义的支出分类
  static const List<Category> expenseCategories = [
    Category(name: '餐饮', icon: Icons.restaurant, color: Color(0xFFFF6B6B)),
    Category(name: '交通', icon: Icons.directions_bus, color: Color(0xFF4ECDC4)),
    Category(name: '购物', icon: Icons.shopping_bag, color: Color(0xFFFFE66D)),
    Category(name: '娱乐', icon: Icons.movie, color: Color(0xFFA8E6CF)),
    Category(name: '医疗', icon: Icons.local_hospital, color: Color(0xFFFF8A80)),
    Category(name: '教育', icon: Icons.school, color: Color(0xFF82B1FF)),
    Category(name: '通讯', icon: Icons.phone, color: Color(0xFFB388FF)),
    Category(name: '住房', icon: Icons.home, color: Color(0xFFFFAB91)),
    Category(name: '日用', icon: Icons.category, color: Color(0xFF80CBC4)),
    Category(name: '转账', icon: Icons.swap_horiz, color: Color(0xFFCE93D8)),
    Category(name: '红包', icon: Icons.card_giftcard, color: Color(0xFFEF5350)),
    Category(name: '其他', icon: Icons.more_horiz, color: Color(0xFF90A4AE)),
  ];

  /// 预定义的收入分类
  static const List<Category> incomeCategories = [
    Category(name: '工资', icon: Icons.account_balance, color: Color(0xFF4CAF50)),
    Category(name: '奖金', icon: Icons.star, color: Color(0xFFFFC107)),
    Category(name: '转账', icon: Icons.swap_horiz, color: Color(0xFF2196F3)),
    Category(name: '红包', icon: Icons.card_giftcard, color: Color(0xFFEF5350)),
    Category(name: '退款', icon: Icons.undo, color: Color(0xFF9C27B0)),
    Category(name: '其他', icon: Icons.more_horiz, color: Color(0xFF607D8B)),
  ];

  /// 根据分类名获取 Category 对象
  static Category? findByName(String name, {bool isExpense = true}) {
    final list = isExpense ? expenseCategories : incomeCategories;
    try {
      return list.firstWhere((c) => c.name == name);
    } catch (_) {
      return list.last; // 返回"其他"
    }
  }
}
