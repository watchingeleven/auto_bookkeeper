import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

/// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('设置')),
          body: ListView(
            children: [
              const SizedBox(height: 8),
              // 通知权限设置
              _buildSection(
                context,
                title: '通知监听',
                children: [
                  ListTile(
                    leading: Icon(
                      appState.isListening
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: appState.isListening ? Colors.green : Colors.red,
                    ),
                    title: const Text('通知访问权限'),
                    subtitle: Text(
                      appState.isListening ? '已开启 - 正在监听支付通知' : '未开启 - 请授权通知访问',
                    ),
                    trailing: appState.isListening
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      await appState.openNotificationSettings();
                    },
                  ),
                ],
              ),
              // 云端同步
              _buildSection(
                context,
                title: '数据同步',
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_upload),
                    title: const Text('同步到云端'),
                    subtitle: const Text('将本地未同步的记录上传'),
                    trailing: appState.isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: appState.isSyncing
                        ? null
                        : () async {
                            final count = await appState.syncToCloud();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('已同步 $count 条记录到云端')),
                              );
                            }
                          },
                  ),
                  ListTile(
                    leading: const Icon(Icons.cloud_download),
                    title: const Text('从云端恢复'),
                    subtitle: const Text('从云端下载历史记录到本地'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('确认恢复'),
                          content: const Text('将从云端下载所有记录到本地，可能会有重复数据。确认继续？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('确认'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final count = await appState.syncFromCloud();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已恢复 $count 条记录')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              // 支持的支付方式
              _buildSection(
                context,
                title: '支持的支付方式',
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFF1677FF),
                    ),
                    title: const Text('支付宝'),
                    subtitle: const Text('自动识别支付宝付款/收款通知'),
                    trailing: const Icon(Icons.check, color: Colors.green),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.wechat,
                      color: Color(0xFF07C160),
                    ),
                    title: const Text('微信支付'),
                    subtitle: const Text('自动识别微信支付/转账/红包通知'),
                    trailing: const Icon(Icons.check, color: Colors.green),
                  ),
                ],
              ),
              // 关于
              _buildSection(
                context,
                title: '关于',
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('版本'),
                    trailing: Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('使用说明'),
                    onTap: () => _showHelpDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('使用说明'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. 首次使用请开启「通知访问权限」'),
              SizedBox(height: 8),
              Text('2. 在设置中找到「自动记账」并开启权限'),
              SizedBox(height: 8),
              Text('3. 使用支付宝或微信支付后，系统将自动识别通知并记账'),
              SizedBox(height: 8),
              Text('4. 自动识别支付金额、商家和消费类型'),
              SizedBox(height: 8),
              Text('5. 可在账单列表查看和管理记录'),
              SizedBox(height: 8),
              Text('6. 支持云端同步，多设备查看'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
