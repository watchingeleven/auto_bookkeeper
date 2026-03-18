import 'package:flutter/material.dart';
import '../models/category.dart' as cat;
import '../models/transaction.dart';
import 'package:intl/intl.dart';

/// 交易记录卡片组件
class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final category = cat.Category.findByName(
      transaction.category,
      isExpense: transaction.isExpense,
    );
    final isExpense = transaction.isExpense;
    final amountStr = isExpense
        ? '-¥${transaction.amount.toStringAsFixed(2)}'
        : '+¥${transaction.amount.toStringAsFixed(2)}';
    final amountColor = isExpense ? Colors.red[600] : Colors.green[600];

    final paymentIcon = transaction.paymentMethod == 'alipay'
        ? Icons.account_balance_wallet
        : Icons.wechat;
    final paymentColor = transaction.paymentMethod == 'alipay'
        ? const Color(0xFF1677FF)
        : const Color(0xFF07C160);

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这条记录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 分类图标
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (category?.color ?? Colors.grey).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category?.icon ?? Icons.receipt,
                    color: category?.color ?? Colors.grey,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // 商家和分类
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchant.isNotEmpty
                            ? transaction.merchant
                            : transaction.category,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(paymentIcon, size: 14, color: paymentColor),
                          const SizedBox(width: 4),
                          Text(
                            '${transaction.category} · ${DateFormat('HH:mm').format(transaction.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 金额
                Text(
                  amountStr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
