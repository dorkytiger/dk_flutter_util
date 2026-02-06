import 'package:dk_util/log/dk_log_example.dart';
import 'package:dk_util/log/dk_log_view.dart';
import 'package:dk_util/state/dk_state_example.dart';
import 'package:flutter/material.dart';

/// 应用路由配置
class AppRoutes {
  static const String home = '/';
  static const String logExample = '/log-example';
  static const String logView = '/log-view';
  static const String stateQueryExample = '/state-query-example';
  static const String stateEventExample = '/state-event-example';
  static const String stateCombinedExample = '/state-combined-example';

  /// 路由表
  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const ExampleHomePage(),
    logExample: (context) => const DKLogFlutterExample(),
    logView: (context) => DKLogView(),
    stateQueryExample: (context) => const StateQueryExample(),
    stateEventExample: (context) => const StateEventExample(),
    stateCombinedExample: (context) => const CombinedStateExample(),
  };
}

/// 示例首页 - 展示所有可用示例
class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DK Util 示例'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, '快速开始'),
          const Divider(),
          _buildSectionHeader(context, 'Log 日志工具'),
          _buildExampleTile(
            context,
            icon: Icons.article_outlined,
            title: 'DKLog 使用示例',
            subtitle: '展示日志工具的各种用法',
            route: AppRoutes.logExample,
          ),
          _buildExampleTile(
            context,
            icon: Icons.list_alt,
            title: 'DKLog 日志查看器',
            subtitle: '查看和管理日志文件',
            route: AppRoutes.logView,
          ),
          const Divider(),
          _buildSectionHeader(context, 'State 状态管理'),
          _buildExampleTile(
            context,
            icon: Icons.cloud_download_outlined,
            title: 'DKStateQuery 示例',
            subtitle: 'GET 查询操作的状态管理',
            route: AppRoutes.stateQueryExample,
          ),
          _buildExampleTile(
            context,
            icon: Icons.send_outlined,
            title: 'DKStateEvent 示例',
            subtitle: 'POST/PUT/DELETE 等一次性事件',
            route: AppRoutes.stateEventExample,
          ),
          _buildExampleTile(
            context,
            icon: Icons.merge_type_outlined,
            title: '组合使用示例',
            subtitle: 'Query + Event 组合使用',
            route: AppRoutes.stateCombinedExample,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildExampleTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}
