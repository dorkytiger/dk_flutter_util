import 'package:flutter/material.dart';

import 'dk_log.dart';
import 'dk_log_view.dart';

/// DKLog 使用示例
///
/// 本文件包含 DKLog 日志工具的完整使用示例

// ==============================================================================
// 基本用法示例（可直接运行）
// ==============================================================================

void basicLogExample() {
  // ========== 基本日志级别 ==========

  // 调试日志（青色）- 用于开发调试
  DKLog.d('这是一条调试信息');

  // 信息日志（白色）- 用于一般信息
  DKLog.i('这是一条普通信息');

  // 成功日志（绿色）- 用于成功提示
  DKLog.s('这是一条成功信息');

  // 警告日志（黄色）- 用于警告信息
  DKLog.w('这是一条警告信息');

  // 错误日志（红色）- 用于错误信息
  DKLog.e('这是一条错误信息');

  // 严重错误日志（紫色）- 用于严重错误
  DKLog.f('这是一条严重错误信息');

  // 临时调试日志（橙色）- 用于临时调试，方便后续清理
  DKLog.t('这是临时调试信息');

  // ========== 带标签的日志 ==========
  DKLog.separator();
  DKLog.i('用户登录成功', tag: 'Auth');
  DKLog.e('网络请求失败', tag: 'Network');
  DKLog.d('数据库查询完成', tag: 'Database');

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
    'settings': {'theme': 'dark', 'notifications': true},
  };
  DKLog.json(user, tag: 'UserData');
}

// ==============================================================================
// 配置示例
// ==============================================================================

void configurationExample() {
  // ========== 日志级别配置 ==========

  // 设置日志级别（只显示 warning 及以上级别）
  DKLog.setLevel(DKLogLevel.warning);
  DKLog.d('这条调试信息不会显示');
  DKLog.i('这条普通信息也不会显示');
  DKLog.w('这条警告信息会显示');

  // 恢复默认级别
  DKLog.setLevel(DKLogLevel.debug);

  // ========== 显示选项配置 ==========

  // 禁用颜色输出
  DKLog.setUseColor(false);
  DKLog.i('这条信息没有颜色');
  DKLog.setUseColor(true);

  // 禁用时间戳
  DKLog.setShowTimestamp(false);
  DKLog.i('这条信息没有时间戳');
  DKLog.setShowTimestamp(true);

  // 禁用位置信息
  DKLog.setShowLocation(false);
  DKLog.i('这条信息没有文件位置');
  DKLog.setShowLocation(true);

  // 完全禁用日志
  DKLog.setEnabled(false);
  DKLog.i('这条信息不会显示');
  DKLog.setEnabled(true);
  DKLog.i('日志已重新启用');

  // ========== 标签过滤配置 ==========

  // 只显示指定标签的日志
  DKLog.setIncludeTags({'Network', 'API'});
  DKLog.i('这条会显示', tag: 'Network');
  DKLog.i('这条也会显示', tag: 'API');
  DKLog.i('这条不会显示', tag: 'Database');
  DKLog.clearIncludeTags(); // 清空过滤，显示所有

  // 排除指定标签的日志
  DKLog.setExcludeTags({'Debug', 'Verbose'});
  DKLog.i('这条会显示', tag: 'Network');
  DKLog.i('这条不会显示', tag: 'Debug');
  DKLog.clearExcludeTags(); // 清空排除列表
}

// ==============================================================================
// Flutter 应用集成示例
// ==============================================================================

/// Flutter 应用入口示例
///
/// 展示如何在 Flutter 应用中初始化 DKLog
Future<void> flutterAppMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 检查并请求存储权限（可选，应用私有目录不需要）
  if (!await DKLog.hasStoragePermission()) {
    await DKLog.requestStoragePermission();
  }

  // 2. 初始化文件日志
  await DKLog.initFileLog(
    enable: true,
    fileLogLevel: DKLogLevel.info, // 只记录 info 及以上级别到文件
    maxFileSize: 10 * 1024 * 1024, // 单文件最大 10MB
    maxFileCount: 5, // 最多保留 5 个日志文件
  );

  // 3. （可选）启用 WebSocket 日志传输
  // await DKLog.enableWebSocketLog(
  //   webSocketLogLevel: DKLogLevel.debug,
  //   autoDiscover: true, // 自动发现服务器
  // );

  // 4. 记录应用启动
  DKLog.i('应用启动', tag: 'App');

  // runApp(const MyApp());
}

/// Flutter Widget 中使用 DKLog 示例
class DKLogFlutterExample extends StatefulWidget {
  const DKLogFlutterExample({super.key});

  @override
  State<DKLogFlutterExample> createState() => _DKLogFlutterExampleState();
}

class _DKLogFlutterExampleState extends State<DKLogFlutterExample> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    DKLog.d('Widget 初始化', tag: 'Lifecycle');
  }

  @override
  void dispose() {
    DKLog.d('Widget 销毁', tag: 'Lifecycle');
    super.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
      DKLog.d('计数器更新: $_counter', tag: 'State');
    });
  }

  Future<void> _mockNetworkRequest() async {
    DKLog.i('开始网络请求', tag: 'Network');
    final stopwatch = Stopwatch()..start();

    try {
      // 模拟网络请求
      await Future.delayed(const Duration(seconds: 1));
      stopwatch.stop();

      DKLog.s('请求成功，耗时: ${stopwatch.elapsedMilliseconds}ms', tag: 'Network');

      // 记录响应数据
      final responseData = {'status': 'ok', 'data': [1, 2, 3]};
      DKLog.json(responseData, tag: 'Network');
    } catch (e, stackTrace) {
      stopwatch.stop();
      DKLog.e('请求失败', tag: 'Network', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DKLog 示例'),
        actions: [
          // 打开日志查看器
          IconButton(
            icon: const Icon(Icons.article),
            tooltip: '查看日志',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DKLogView()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('计数器: $_counter'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _mockNetworkRequest,
              child: const Text('模拟网络请求'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _logDifferentLevels(),
              child: const Text('输出不同级别日志'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _exportLogs(),
              child: const Text('导出日志'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _logDifferentLevels() {
    DKLog.d('Debug 级别日志', tag: 'Test');
    DKLog.i('Info 级别日志', tag: 'Test');
    DKLog.s('Success 级别日志', tag: 'Test');
    DKLog.w('Warning 级别日志', tag: 'Test');
    DKLog.e('Error 级别日志', tag: 'Test');
    DKLog.f('Fatal 级别日志', tag: 'Test');
    DKLog.t('Temp 临时调试日志');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已输出不同级别日志，请查看控制台')),
    );
  }

  Future<void> _exportLogs() async {
    DKLog.i('开始导出日志', tag: 'Export');

    final path = await DKLog.exportLogs();

    if (mounted) {
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('日志已导出到: $path')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日志导出失败')),
        );
      }
    }
  }
}

// ==============================================================================
// 文件日志管理示例
// ==============================================================================

/// 文件日志操作示例
class FileLogExample {
  /// 初始化文件日志
  static Future<void> init() async {
    await DKLog.initFileLog(
      enable: true,
      fileLogLevel: DKLogLevel.info, // 只记录 info 及以上级别
      maxFileSize: 5 * 1024 * 1024, // 5MB
      maxFileCount: 3, // 保留 3 个文件
    );
  }

  /// 获取所有日志文件
  static Future<void> listLogFiles() async {
    final files = await DKLog.getLogFiles();
    DKLog.i('找到 ${files.length} 个日志文件', tag: 'FileLog');

    for (final file in files) {
      final stat = await file.stat();
      DKLog.d(
        '文件: ${file.path.split('/').last}, 大小: ${stat.size} 字节',
        tag: 'FileLog',
      );
    }
  }

  /// 读取日志文件内容
  static Future<String?> readLatestLog() async {
    final files = await DKLog.getLogFiles();
    if (files.isEmpty) return null;

    final latestFile = files.first;
    return await latestFile.readAsString();
  }

  /// 导出日志
  static Future<String?> exportLogs() async {
    return await DKLog.exportLogs();
  }

  /// 清空所有日志
  static Future<void> clearLogs() async {
    await DKLog.clearAllLogs();
    DKLog.i('所有日志已清空', tag: 'FileLog');
  }
}

// ==============================================================================
// WebSocket 日志传输示例
// ==============================================================================

/// WebSocket 日志示例
///
/// 用于将日志实时传输到电脑端查看
class WebSocketLogExample {
  /// 启用 WebSocket 日志（自动发现服务器）
  static Future<void> enableAutoDiscover() async {
    await DKLog.enableWebSocketLog(
      webSocketLogLevel: DKLogLevel.debug, // 传输所有级别
      autoDiscover: true, // 自动通过 mDNS 发现服务器
    );
  }

  /// 启用 WebSocket 日志（手动指定服务器）
  static Future<void> enableManual() async {
    await DKLog.enableWebSocketLog(
      webSocketLogLevel: DKLogLevel.info, // 只传输 info 及以上
      autoDiscover: false,
      host: '192.168.1.100',
      port: 9090,
      path: '/logs',
    );
  }

  /// 禁用 WebSocket 日志
  static Future<void> disable() async {
    await DKLog.disableWebSocketLog();
  }

  /// 检查连接状态
  static void checkStatus() {
    if (DKLog.isWebSocketEnabled) {
      DKLog.i(
        'WebSocket 状态: ${DKLog.isWebSocketConnected ? "已连接" : "未连接"}',
        tag: 'WebSocket',
      );
    } else {
      DKLog.i('WebSocket 未启用', tag: 'WebSocket');
    }
  }

  /// 手动重连
  static Future<void> reconnect() async {
    await DKLog.reconnectWebSocket();
  }

  /// 设置连接状态回调
  static void setConnectionCallback() {
    DKLog.setWebSocketConnectionCallback((connected) {
      DKLog.i(
        'WebSocket ${connected ? "已连接" : "已断开"}',
        tag: 'WebSocket',
      );
    });
  }
}

// ==============================================================================
// 实际应用场景示例
// ==============================================================================

/// 网络请求日志示例
class NetworkLogExample {
  static Future<void> fetchData(String url) async {
    final requestId = DateTime.now().millisecondsSinceEpoch;
    DKLog.i('[$requestId] 开始请求: $url', tag: 'HTTP');

    final stopwatch = Stopwatch()..start();

    try {
      // 模拟请求
      await Future.delayed(const Duration(seconds: 1));

      stopwatch.stop();
      DKLog.s(
        '[$requestId] 请求成功，耗时: ${stopwatch.elapsedMilliseconds}ms',
        tag: 'HTTP',
      );

      // 记录响应
      final response = {'code': 200, 'message': 'success'};
      DKLog.json(response, tag: 'HTTP-Response');
    } catch (e, stack) {
      stopwatch.stop();
      DKLog.e(
        '[$requestId] 请求失败，耗时: ${stopwatch.elapsedMilliseconds}ms',
        tag: 'HTTP',
        error: e,
        stackTrace: stack,
      );
    }
  }
}

/// 用户行为日志示例
class UserBehaviorLogExample {
  static void logPageView(String pageName) {
    DKLog.i('页面访问: $pageName', tag: 'Analytics');
  }

  static void logButtonClick(String buttonName) {
    DKLog.i('按钮点击: $buttonName', tag: 'Analytics');
  }

  static void logUserAction(String action, Map<String, dynamic> params) {
    DKLog.i('用户操作: $action', tag: 'Analytics');
    DKLog.json(params, tag: 'Analytics');
  }
}

/// 性能监控日志示例
class PerformanceLogExample {
  static void logFrameRate(double fps) {
    if (fps < 30) {
      DKLog.w('帧率过低: ${fps.toStringAsFixed(1)} FPS', tag: 'Performance');
    } else {
      DKLog.d('帧率: ${fps.toStringAsFixed(1)} FPS', tag: 'Performance');
    }
  }

  static void logMemoryUsage(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb > 200) {
      DKLog.w('内存使用过高: ${mb.toStringAsFixed(1)} MB', tag: 'Performance');
    } else {
      DKLog.d('内存使用: ${mb.toStringAsFixed(1)} MB', tag: 'Performance');
    }
  }

  static Future<T> measureAsync<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      DKLog.i(
        '$name 耗时: ${stopwatch.elapsedMilliseconds}ms',
        tag: 'Performance',
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      DKLog.e(
        '$name 失败，耗时: ${stopwatch.elapsedMilliseconds}ms',
        tag: 'Performance',
        error: e,
      );
      rethrow;
    }
  }
}

// ==============================================================================
// 使用说明
// ==============================================================================

/// # DKLog 使用总结
///
/// ## 日志级别
/// - `DKLog.d()` - Debug，调试信息（青色）
/// - `DKLog.i()` - Info，一般信息（白色）
/// - `DKLog.s()` - Success，成功信息（绿色）
/// - `DKLog.w()` - Warning，警告信息（黄色）
/// - `DKLog.e()` - Error，错误信息（红色）
/// - `DKLog.f()` - Fatal，严重错误（紫色）
/// - `DKLog.t()` - Temp，临时调试（橙色）
///
/// ## 常用参数
/// - `tag` - 日志标签，用于分类
/// - `error` - 错误对象
/// - `stackTrace` - 堆栈信息
///
/// ## 特殊方法
/// - `DKLog.json()` - 格式化输出 JSON
/// - `DKLog.separator()` - 输出分隔线
///
/// ## 配置方法
/// - `DKLog.setLevel()` - 设置日志级别
/// - `DKLog.setEnabled()` - 启用/禁用日志
/// - `DKLog.setShowTimestamp()` - 显示时间戳
/// - `DKLog.setShowLocation()` - 显示调用位置
/// - `DKLog.setUseColor()` - 使用颜色
/// - `DKLog.setIncludeTags()` - 只显示指定标签
/// - `DKLog.setExcludeTags()` - 排除指定标签
///
/// ## 文件日志
/// - `DKLog.initFileLog()` - 初始化文件日志
/// - `DKLog.getLogFiles()` - 获取日志文件列表
/// - `DKLog.exportLogs()` - 导出日志
/// - `DKLog.clearAllLogs()` - 清空日志
///
/// ## WebSocket 日志
/// - `DKLog.enableWebSocketLog()` - 启用远程日志
/// - `DKLog.disableWebSocketLog()` - 禁用远程日志
/// - `DKLog.isWebSocketConnected` - 检查连接状态

