import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_state.dart';
import '../models/category.dart' as cat;

/// 统计页面
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final stats = appState.categoryStats;
        final totalExpense = appState.monthlyExpense;

        return Scaffold(
          appBar: AppBar(title: const Text('月度统计')),
          body: stats.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('暂无统计数据', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 月度收支概览
                      _buildOverviewCard(appState),
                      const SizedBox(height: 20),
                      // 分类饼图
                      _buildPieChart(stats, totalExpense),
                      const SizedBox(height: 20),
                      // 分类列表
                      _buildCategoryList(stats, totalExpense),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildOverviewCard(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatColumn(
                '支出',
                appState.monthlyExpense,
                Colors.red[600]!,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey[200]),
            Expanded(
              child: _buildStatColumn(
                '收入',
                appState.monthlyIncome,
                Colors.green[600]!,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey[200]),
            Expanded(
              child: _buildStatColumn(
                '结余',
                appState.monthlyIncome - appState.monthlyExpense,
                Colors.blue[600]!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          '¥${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, double> stats, double total) {
    if (total == 0) return const SizedBox.shrink();

    final entries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: entries.map((entry) {
                final category = cat.Category.findByName(entry.key);
                final percentage = (entry.value / total * 100);
                return PieChartSectionData(
                  value: entry.value,
                  color: category?.color ?? Colors.grey,
                  title: percentage >= 5
                      ? '${percentage.toStringAsFixed(0)}%'
                      : '',
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  radius: 50,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(Map<String, double> stats, double total) {
    final entries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '支出分类',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...entries.map((entry) {
            final category = cat.Category.findByName(entry.key);
            final percentage = total > 0 ? (entry.value / total * 100) : 0.0;

            return ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (category?.color ?? Colors.grey).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category?.icon ?? Icons.category,
                  color: category?.color ?? Colors.grey,
                  size: 18,
                ),
              ),
              title: Text(entry.key),
              subtitle: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    category?.color ?? Colors.grey,
                  ),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥${entry.value.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
