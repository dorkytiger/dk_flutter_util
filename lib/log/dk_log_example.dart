import 'dk_log.dart';

/// DkLog 使用示例
void main() {
  // ========== 基本用法 ==========

  // 调试日志
  DKLog.d('这是一条调试信息');

  // 信息日志
  DKLog.i('这是一条普通信息');

  // 警告日志
  DKLog.w('这是一条警告信息');

  // 错误日志
  DKLog.e('这是一条错误信息');

  // 严重错误日志
  DKLog.f('这是一条严重错误信息');

  // ========== 带标签的日志 ==========
  DKLog.separator();
  DKLog.i('用户登录成功', tag: 'Auth');
  DKLog.e('网络请求失败', tag: 'Network');

  // ========== 带错误对象的日志 ==========
  DKLog.separator();
  try {
    throw Exception('发生了一个异常');
  } catch (e, stackTrace) {
    DKLog.e('捕获到异常', error: e, stackTrace: stackTrace);
  }

  // ========== JSON 格式化输出 ==========
  DKLog.separator();
  final user = {
    'id': 1001,
    'name': 'DorkyTiger',
    'email': 'dorkytiger@example.com',
    'roles': ['admin', 'user'],
    'settings': {
      'theme': 'dark',
      'notifications': true,
    }
  };
  DKLog.json(user, tag: 'UserData');

  // ========== 配置示例 ==========
  DKLog.separator(char: '=');

  // 设置日志级别（只显示 warning 及以上级别）
  DKLog.setLevel(DKLogLevel.warning);
  DKLog.d('这条调试信息不会显示');
  DKLog.i('这条普通信息也不会显示');
  DKLog.w('这条警告信息会显示');

  // 恢复默认级别
  DKLog.setLevel(DKLogLevel.debug);

  // 禁用颜色输出
  DKLog.setUseColor(false);
  DKLog.i('这条信息没有颜色');

  // 启用颜色
  DKLog.setUseColor(true);

  // 禁用时间戳
  DKLog.setShowTimestamp(false);
  DKLog.i('这条信息没有时间戳');

  // 启用时间戳
  DKLog.setShowTimestamp(true);

  // 禁用位置信息
  DKLog.setShowLocation(false);
  DKLog.i('这条信息没有文件位置');

  // 启用位置信息
  DKLog.setShowLocation(true);

  // 完全禁用日志
  DKLog.setEnabled(false);
  DKLog.i('这条信息不会显示');

  // 重新启用日志
  DKLog.setEnabled(true);
  DKLog.i('日志已重新启用');

  // ========== 在 Flutter 中的使用示例 ==========
  DKLog.separator(char: '=');

  // 在 initState 中
  DKLog.d('Widget 初始化', tag: 'Lifecycle');

  // 在网络请求中
  DKLog.i('开始请求数据', tag: 'API');
  DKLog.d('请求 URL: https://api.example.com/users', tag: 'API');

  // 模拟网络响应
  DKLog.i('请求成功', tag: 'API');

  // 在状态管理中
  DKLog.d('状态更新: counter = 10', tag: 'State');

  // 性能监控
  final stopwatch = Stopwatch()..start();
  // 执行一些操作
  stopwatch.stop();
  DKLog.i('操作耗时: ${stopwatch.elapsedMilliseconds}ms', tag: 'Performance');

  DKLog.separator(char: '=');
  DKLog.i('示例结束');
}
