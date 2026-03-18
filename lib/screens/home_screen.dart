import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../models/transaction.dart';
import '../widgets/transaction_card.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

/// 主页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _TransactionListPage(),
          StatisticsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '账单',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

/// 交易记录列表页
class _TransactionListPage extends StatelessWidget {
  const _TransactionListPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return CustomScrollView(
          slivers: [
            // 顶部概览
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildSummaryHeader(context, appState),
              ),
              title: const Text('自动记账'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: appState.isSyncing
                      ? null
                      : () async {
                          final count = await appState.syncToCloud();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('已同步 $count 条记录')),
                            );
                          }
                        },
                ),
              ],
            ),
            // 监听状态提示
            if (!appState.isListening)
              SliverToBoxAdapter(
                child: _buildPermissionBanner(context, appState),
              ),
            // 交易记录列表
            if (appState.transactions.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        '暂无记录',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '支付宝/微信支付后将自动记录',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= appState.transactions.length) return null;

                    final transaction = appState.transactions[index];
                    final showDateHeader = index == 0 ||
                        !_isSameDay(
                          transaction.createdAt,
                          appState.transactions[index - 1].createdAt,
                        );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Text(
                              _formatDateHeader(transaction.createdAt),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        TransactionCard(
                          transaction: transaction,
                          onTap: () => _showTransactionDetail(
                              context, transaction, appState),
                          onDelete: () =>
                              appState.deleteTransaction(transaction.id),
                        ),
                      ],
                    );
                  },
                  childCount: appState.transactions.length,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryHeader(BuildContext context, AppState appState) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${DateFormat('M月').format(DateTime.now())}支出',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '¥${appState.monthlyExpense.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMiniStat('收入', appState.monthlyIncome, Colors.white),
                  const SizedBox(width: 24),
                  _buildMiniStat(
                    '结余',
                    appState.monthlyIncome - appState.monthlyExpense,
                    Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, double amount, Color color) {
    return Row(
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.7),
          ),
        ),
        Text(
          '¥${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionBanner(BuildContext context, AppState appState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '未开启通知监听',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '请开启通知访问权限以自动识别支付通知',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[600],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await appState.openNotificationSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetail(
    BuildContext context,
    Transaction transaction,
    AppState appState,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TransactionDetailSheet(
        transaction: transaction,
        onUpdate: (updated) => appState.updateTransaction(updated),
        onDelete: () => appState.deleteTransaction(transaction.id),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return '今天';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return '昨天';
    return DateFormat('M月d日 EEEE', 'zh_CN').format(date);
  }
}

/// 交易记录详情底部弹窗
class _TransactionDetailSheet extends StatelessWidget {
  final Transaction transaction;
  final Function(Transaction) onUpdate;
  final VoidCallback onDelete;

  const _TransactionDetailSheet({
    required this.transaction,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final paymentLabel =
        transaction.paymentMethod == 'alipay' ? '支付宝' : '微信支付';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖动条
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 金额
          Center(
            child: Text(
              '${transaction.isExpense ? "-" : "+"}¥${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: transaction.isExpense ? Colors.red[600] : Colors.green[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailRow('商家', transaction.merchant.isNotEmpty ? transaction.merchant : '-'),
          _buildDetailRow('分类', transaction.category),
          _buildDetailRow('支付方式', paymentLabel),
          _buildDetailRow('时间', DateFormat('yyyy-MM-dd HH:mm:ss').format(transaction.createdAt)),
          _buildDetailRow('备注', transaction.note ?? '-'),
          const SizedBox(height: 16),
          // 原始通知内容（可展开）
          ExpansionTile(
            title: const Text('原始通知', style: TextStyle(fontSize: 14)),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  transaction.rawNotification,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('确认'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
