import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'log_websocket_client.dart';

/// 日志级别
enum DKLogLevel {
  /// 调试信息
  debug(0, '🐛 DEBUG', '\x1B[36m'),

  /// 普通信息
  info(1, 'ℹ️  INFO', '\x1B[37m'),

  /// 警告信息
  warning(2, '⚠️  WARN', '\x1B[33m'),

  /// 错误信息
  error(3, '❌ ERROR', '\x1B[31m'),

  /// 严重错误
  fatal(4, '💀 FATAL', '\x1B[35m'),

  /// 成功信息
  success(5, '✅ SUCCESS', '\x1B[32m'),

  /// 临时调试（橙色，用于开发时的临时log，方便识别和清理）
  temp(6, '🔶 TEMP', '\x1B[38;5;208m');

  const DKLogLevel(this.value, this.label, this.color);

  final int value;
  final String label;
  final String color;
}

/// 日志工具类
///
/// 日志格式说明：
/// - 时间戳: `<HH:MM:SS.mmm>` 使用尖括号
/// - 日志级别: `[LEVEL]` 使用方括号，如 [ERROR]、[INFO]
/// - 标签: `#TagName` 使用井号前缀
/// - 调用位置: `@file.dart:123` 使用@符号前缀
/// - 消息内容: `: message` 冒号后跟消息
///
/// 完整示例:
/// ```
/// <12:34:56.789> [INFO] #Network @api_service.dart:45: 请求成功
/// <12:34:56.790> [ERROR] #Database @db_helper.dart:123: 连接失败 {"error": "timeout"}
/// ```
///
/// 这种格式设计使得：
/// 1. 容易区分日志的各个部分
/// 2. 搜索时不会与消息内容（如JSON）中的[]混淆
/// 3. 可以使用正则表达式精确匹配特定部分
///    - 搜索时间戳: `<\d{2}:\d{2}:\d{2}\.\d{3}>`
///    - 搜索标签: `#TagName`
///    - 搜索位置: `@filename\.dart:\d+`
class DKLog {
  DKLog._();

  /// 当前日志级别，低于此级别的日志不会输出
  static DKLogLevel _currentLevel = DKLogLevel.debug;

  /// 是否启用日志
  static bool _enabled = true;

  /// 是否显示时间戳
  static bool _showTimestamp = true;

  /// 是否显示调用位置
  static bool _showLocation = true;

  /// 是否使用颜色输出
  static bool _useColor = true;

  /// ANSI 重置颜色
  static const String _resetColor = '\x1B[0m';

  /// 是否写入日志文件
  static bool _writeToFile = true;

  /// 日志文件写入的最低级别
  static DKLogLevel _fileLogLevel = DKLogLevel.info;

  /// 日志文件路径
  static String? _logFilePath;

  /// 日志文件的 IOSink
  static IOSink? _logFileSink;

  /// 最大日志文件大小（字节），默认 10MB
  static int _maxFileSize = 10 * 1024 * 1024;

  /// 最多保留的日志文件数量
  static int _maxFileCount = 5;

  /// 是否已初始化日志文件
  static bool _fileInitialized = false;

  /// 是否启用developer.log输出
  static bool enableDeveloperLog = false;

  /// 只显示这些 tag 的日志（为空则显示所有）
  static Set<String> _includeTags = {};

  /// 不显示这些 tag 的日志
  static Set<String> _excludeTags = {};

  /// 是否启用 WebSocket 日志传输
  static bool _webSocketEnabled = false;

  /// WebSocket 日志传输的最低级别
  static DKLogLevel _webSocketLogLevel = DKLogLevel.debug;

  /// WebSocket 客户端实例
  static final LogWebSocketClient _webSocketClient =
      LogWebSocketClient.instance;

  /// 请求存储权限（可选，应用私有目录不需要）
  ///
  /// 注意：
  /// - 应用私有目录（getApplicationDocumentsDirectory）不需要权限
  /// - 如果需要导出日志到公共目录（如 Downloads），才需要调用此方法
  ///
  /// @return 是否已获得权限
  static Future<bool> requestStoragePermission() async {
    if (kIsWeb) {
      debugPrint('[DKLog] Web 平台不需要存储权限');
      return true;
    }

    if (Platform.isIOS) {
      // iOS 应用私有目录不需要权限
      debugPrint('[DKLog] iOS 应用私有目录不需要权限');
      return true;
    }

    if (Platform.isAndroid) {
      // Android 13+ (API 33+) 使用新的权限模型
      final androidVersion = await _getAndroidVersion();

      if (androidVersion >= 33) {
        // Android 13+ 不需要存储权限访问应用私有目录
        debugPrint('[DKLog] Android 13+ 应用私有目录不需要权限');
        return true;
      } else if (androidVersion >= 30) {
        // Android 11-12 (API 30-32)
        final status = await Permission.storage.status;
        if (status.isGranted) {
          debugPrint('[DKLog] 存储权限已授予');
          return true;
        }

        final result = await Permission.storage.request();
        if (result.isGranted) {
          debugPrint('[DKLog] 存储权限请求成功');
          return true;
        } else if (result.isPermanentlyDenied) {
          debugPrint('[DKLog] 存储权限被永久拒绝，请在设置中手动开启');
          return false;
        } else {
          debugPrint('[DKLog] 存储权限被拒绝');
          return false;
        }
      } else {
        // Android 10 及以下
        final status = await Permission.storage.status;
        if (status.isGranted) {
          return true;
        }

        final result = await Permission.storage.request();
        return result.isGranted;
      }
    }

    // 其他平台默认允许
    return true;
  }

  /// 获取 Android 版本号（仅 Android 平台）
  static Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      // 这里简化处理，实际可以通过 device_info_plus 获取
      // 对于应用私有目录，我们不需要权限，所以直接返回高版本
      return 33;
    } catch (e) {
      return 33;
    }
  }

  /// 检查是否有存储权限
  ///
  /// @return 是否有权限
  static Future<bool> hasStoragePermission() async {
    if (kIsWeb || Platform.isIOS) {
      return true;
    }

    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();
      if (androidVersion >= 30) {
        // Android 11+ 应用私有目录不需要权限
        return true;
      }

      final status = await Permission.storage.status;
      return status.isGranted;
    }

    return true;
  }

  /// 打开应用设置页面（用于手动授权）
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// 初始化日志文件写入
  ///
  /// @param enable 是否启用日志文件写入
  /// @param fileLogLevel 写入文件的最低日志级别
  /// @param maxFileSize 单个日志文件最大大小（字节）
  /// @param maxFileCount 最多保留的日志文件数量
  /// @param requestPermission 是否自动请求权限（默认 false，因为应用私有目录不需要权限）
  static Future<void> initFileLog({
    bool enable = true,
    DKLogLevel fileLogLevel = DKLogLevel.info,
    int maxFileSize = 10 * 1024 * 1024, // 10MB
    int maxFileCount = 5,
    bool requestPermission = false,
  }) async {
    if (kIsWeb) {
      debugPrint('[DKLog] Web 平台不支持文件日志');
      return;
    }

    _writeToFile = enable;
    _fileLogLevel = fileLogLevel;
    _maxFileSize = maxFileSize;
    _maxFileCount = maxFileCount;

    if (!enable) {
      await _closeLogFile();
      _fileInitialized = false;
      return;
    }

    // 可选：请求权限（应用私有目录通常不需要）
    if (requestPermission) {
      final hasPermission = await hasStoragePermission();
      if (!hasPermission) {
        debugPrint('[DKLog] 正在请求存储权限...');
        final granted = await requestStoragePermission();
        if (!granted) {
          debugPrint('[DKLog] 存储权限未授予，日志文件功能将不可用');
          _writeToFile = false;
          return;
        }
      }
    }

    try {
      // 使用应用私有目录，不需要权限
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final now = DateTime.now();
      final fileName =
          'app_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.log';
      _logFilePath = '${logDir.path}/$fileName';

      // 清理旧日志文件
      await _cleanOldLogFiles(logDir);

      _fileInitialized = true;
      debugPrint('[DKLog] 日志文件已初始化: $_logFilePath');
    } catch (e) {
      debugPrint('[DKLog] 初始化日志文件失败: $e');
      _writeToFile = false;
    }
  }

  /// 关闭日志文件
  static Future<void> _closeLogFile() async {
    if (_logFileSink != null) {
      try {
        await _logFileSink!.flush();
        await _logFileSink!.close();
        _logFileSink = null;
      } catch (e) {
        debugPrint('[DKLog] 关闭日志文件失败: $e');
      }
    }
  }

  /// 清理旧的日志文件
  static Future<void> _cleanOldLogFiles(Directory logDir) async {
    try {
      final files = logDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.log'))
          .toList();

      // 按修改时间排序
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      // 删除超过数量限制的文件
      if (files.length > _maxFileCount) {
        for (var i = _maxFileCount; i < files.length; i++) {
          try {
            await files[i].delete();
            debugPrint('[DKLog] 删除旧日志文件: ${files[i].path}');
          } catch (e) {
            debugPrint('[DKLog] 删除日志文件失败: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[DKLog] 清理日志文件失败: $e');
    }
  }

  /// 写入日志到文件
  static Future<void> _writeToLogFile(String logMessage) async {
    if (!_writeToFile || !_fileInitialized || _logFilePath == null) {
      return;
    }

    try {
      // 检查文件大小
      final file = File(_logFilePath!);
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize >= _maxFileSize) {
          // 文件过大，创建新文件
          await _closeLogFile();
          await initFileLog(
            enable: _writeToFile,
            fileLogLevel: _fileLogLevel,
            maxFileSize: _maxFileSize,
            maxFileCount: _maxFileCount,
          );
          return;
        }
      }

      // 写入日志（不带颜色代码）
      final cleanMessage = logMessage.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');

      _logFileSink ??= file.openWrite(mode: FileMode.append);

      _logFileSink!.writeln(cleanMessage);
      // 不需要每次都 flush，让系统自动处理
    } catch (e) {
      debugPrint('[DKLog] 写入日志文件失败: $e');
    }
  }

  /// 获取所有日志文件
  static Future<List<File>> getLogFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!await logDir.exists()) {
        return [];
      }

      final files = logDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.log'))
          .toList();

      // 按修改时间排序（最新的在前）
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      return files;
    } catch (e) {
      debugPrint('[DKLog] 获取日志文件列表失败: $e');
      return [];
    }
  }

  /// 清空所有日志文件
  static Future<void> clearAllLogs() async {
    try {
      await _closeLogFile();

      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (await logDir.exists()) {
        await logDir.delete(recursive: true);
        debugPrint('[DKLog] 已清空所有日志文件');
      }

      _fileInitialized = false;
    } catch (e) {
      debugPrint('[DKLog] 清空日志文件失败: $e');
    }
  }

  /// 导出日志文件到公共目录（需要存储权限）
  ///
  /// @param destinationPath 目标路径，如果为 null 则使用 Downloads 目录
  /// @return 导出的文件路径，失败返回 null
  static Future<String?> exportLogs({String? destinationPath}) async {
    if (kIsWeb) {
      debugPrint('[DKLog] Web 平台不支持导出日志');
      return null;
    }

    try {
      // 检查权限
      if (Platform.isAndroid) {
        final hasPermission = await hasStoragePermission();
        if (!hasPermission) {
          final granted = await requestStoragePermission();
          if (!granted) {
            debugPrint('[DKLog] 导出日志需要存储权限');
            return null;
          }
        }
      }

      // 获取源日志文件
      final logFiles = await getLogFiles();
      if (logFiles.isEmpty) {
        debugPrint('[DKLog] 没有日志文件可导出');
        return null;
      }

      // 确定目标目录
      Directory targetDir;
      if (destinationPath != null) {
        targetDir = Directory(destinationPath);
      } else {
        // 使用 Downloads 目录
        if (Platform.isAndroid) {
          targetDir = Directory('/storage/emulated/0/Download/AppLogs');
        } else if (Platform.isIOS) {
          // iOS 使用应用的 Documents 目录
          final appDir = await getApplicationDocumentsDirectory();
          targetDir = Directory('${appDir.path}/ExportedLogs');
        } else {
          final appDir = await getApplicationDocumentsDirectory();
          targetDir = Directory('${appDir.path}/ExportedLogs');
        }
      }

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // 创建合并的日志文件
      final now = DateTime.now();
      final exportFileName =
          'exported_logs_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.log';
      final exportFile = File('${targetDir.path}/$exportFileName');

      final sink = exportFile.openWrite();

      // 写入导出信息
      sink.writeln('=' * 80);
      sink.writeln('日志导出时间: ${DateTime.now()}');
      sink.writeln('日志文件数量: ${logFiles.length}');
      sink.writeln('=' * 80);
      sink.writeln();

      // 合并所有日志文件
      for (var i = 0; i < logFiles.length; i++) {
        final logFile = logFiles[i];
        sink.writeln('-' * 80);
        sink.writeln('文件 ${i + 1}: ${logFile.path.split('/').last}');
        sink.writeln('修改时间: ${logFile.lastModifiedSync()}');
        sink.writeln('-' * 80);

        final content = await logFile.readAsString();
        sink.writeln(content);
        sink.writeln();
      }

      await sink.flush();
      await sink.close();

      debugPrint('[DKLog] 日志已导出到: ${exportFile.path}');
      return exportFile.path;
    } catch (e, stackTrace) {
      debugPrint('[DKLog] 导出日志失败: $e');
      debugPrint('[DKLog] StackTrace: $stackTrace');
      return null;
    }
  }

  /// 分享日志文件（使用系统分享功能）
  /// 需要添加 share_plus 依赖
  static Future<void> shareLogs() async {
    try {
      final exportPath = await exportLogs();
      if (exportPath != null) {
        debugPrint('[DKLog] 日志文件已准备，路径: $exportPath');
        debugPrint('[DKLog] 提示: 使用 share_plus 包来分享此文件');
        // 如果需要分享功能，可以添加 share_plus 依赖
        // await Share.shareXFiles([XFile(exportPath)], text: '应用日志');
      }
    } catch (e) {
      debugPrint('[DKLog] 分享日志失败: $e');
    }
  }

  /// 设置日志级别
  static void setLevel(DKLogLevel level) {
    _currentLevel = level;
  }

  /// 启用或禁用日志
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// 设置是否显示时间戳
  static void setShowTimestamp(bool show) {
    _showTimestamp = show;
  }

  /// 设置是否显示调用位置
  static void setShowLocation(bool show) {
    _showLocation = show;
  }

  /// 设置是否使用颜色输出
  static void setUseColor(bool use) {
    _useColor = use;
  }

  /// 设置只显示这些 tag 的日志（为空则显示所有）
  ///
  /// 示例：
  /// ```dart
  /// Log.setIncludeTags({'Network', 'Database'});  // 只显示这两个tag的日志
  /// ```
  static void setIncludeTags(Set<String> tags) {
    _includeTags = tags;
  }

  /// 添加到包含列表
  static void addIncludeTag(String tag) {
    _includeTags.add(tag);
  }

  /// 从包含列表移除
  static void removeIncludeTag(String tag) {
    _includeTags.remove(tag);
  }

  /// 清空包含列表（显示所有tag）
  static void clearIncludeTags() {
    _includeTags.clear();
  }

  /// 设置不显示这些 tag 的日志
  ///
  /// 示例：
  /// ```dart
  /// Log.setExcludeTags({'Debug', 'Verbose'});  // 排除这两个tag的日志
  /// ```
  static void setExcludeTags(Set<String> tags) {
    _excludeTags = tags;
  }

  /// 添加到排除列表
  static void addExcludeTag(String tag) {
    _excludeTags.add(tag);
  }

  /// 从排除列表移除
  static void removeExcludeTag(String tag) {
    _excludeTags.remove(tag);
  }

  /// 清空排除列表
  static void clearExcludeTags() {
    _excludeTags.clear();
  }

  /// 获取当前的包含 tag 列表
  static Set<String> getIncludeTags() {
    return Set.from(_includeTags);
  }

  /// 获取当前的排除 tag 列表
  static Set<String> getExcludeTags() {
    return Set.from(_excludeTags);
  }

  /// 启用 WebSocket 日志传输
  ///
  /// 将日志通过 WebSocket 发送到电脑端进行实时查看
  ///
  /// [webSocketLogLevel] - WebSocket 传输的最低日志级别（默认 debug，传输所有级别）
  /// [autoDiscover] - 是否自动通过 mDNS 发现服务器（默认 true）
  /// [host] - 手动指定服务器地址（如果不使用自动发现）
  /// [port] - 手动指定服务器端口（如果不使用自动发现）
  /// [path] - WebSocket 路径（默认为空，例如 '/logs'）
  /// [serviceName] - mDNS 服务名称（可选，用于指定特定服务器）
  ///
  /// 示例：
  /// ```dart
  /// // 自动发现服务器
  /// await Log.enableWebSocketLog();
  ///
  /// // 手动指定服务器
  /// await Log.enableWebSocketLog(
  ///   autoDiscover: false,
  ///   host: '192.168.1.100',
  ///   port: 9090,
  ///   path: '/logs',
  /// );
  ///
  /// // 只传输 INFO 及以上级别的日志
  /// await Log.enableWebSocketLog(
  ///   webSocketLogLevel: LogLevel.info,
  /// );
  /// ```
  static Future<void> enableWebSocketLog({
    DKLogLevel webSocketLogLevel = DKLogLevel.debug,
    bool autoDiscover = true,
    String? host,
    int? port,
    String? path,
    String? serviceName,
  }) async {
    if (kIsWeb) {
      debugPrint('[DKLog] Web 平台暂不支持 WebSocket 日志传输');
      return;
    }

    _webSocketEnabled = true;
    _webSocketLogLevel = webSocketLogLevel;

    await _webSocketClient.enable(
      autoDiscover: autoDiscover,
      host: host,
      port: port,
      path: path,
      serviceName: serviceName,
    );

    debugPrint('[DKLog] WebSocket 日志传输已启用');
  }

  /// 禁用 WebSocket 日志传输
  static Future<void> disableWebSocketLog() async {
    if (!_webSocketEnabled) {
      return;
    }

    _webSocketEnabled = false;
    await _webSocketClient.disable();
    debugPrint('[DKLog] WebSocket 日志传输已禁用');
  }

  /// 设置 WebSocket 连接状态变化回调
  static void setWebSocketConnectionCallback(
    void Function(bool connected)? callback,
  ) {
    _webSocketClient.onConnectionStatusChanged = callback;
  }

  /// 获取 WebSocket 连接状态
  static bool get isWebSocketConnected => _webSocketClient.isConnected;

  /// 获取 WebSocket 是否已启用
  static bool get isWebSocketEnabled => _webSocketEnabled;

  /// 手动重连 WebSocket（用于界面按钮）
  static Future<void> reconnectWebSocket() async {
    if (!_webSocketEnabled) {
      debugPrint('[DKLog] WebSocket 未启用，无法重连');
      return;
    }
    await _webSocketClient.reconnect();
  }

  /// 检查 tag 是否应该被过滤（不显示）
  static bool _shouldFilterTag(String? tag) {
    // 如果没有tag，默认不过滤
    if (tag == null || tag.isEmpty) {
      // 但如果设置了包含列表且不为空，则过滤掉无tag的日志
      if (_includeTags.isNotEmpty) {
        return true;
      }
      return false;
    }

    // 如果在排除列表中，则过滤
    if (_excludeTags.contains(tag)) {
      return true;
    }

    // 如果设置了包含列表且不为空，检查是否在列表中
    if (_includeTags.isNotEmpty) {
      return !_includeTags.contains(tag);
    }

    // 默认不过滤
    return false;
  }

  /// 调试日志
  static void d(
    dynamic message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DKLogLevel.debug,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 信息日志
  static void i(
    dynamic message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DKLogLevel.info,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 成功日志
  static void s(
    dynamic message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DKLogLevel.success,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 警告日志
  static void w(
    dynamic message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DKLogLevel.warning,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 错误日志
  static void e(
    dynamic message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DKLogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 严重错误日志
  static void f(
    dynamic message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DKLogLevel.fatal,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 临时调试日志（橙色）
  ///
  /// 专门用于开发时的临时调试代码，带有明显标志方便后续清理
  /// 默认使用 "TEMP" 标签，建议开发完成后搜索并删除此类日志
  ///
  /// 示例：
  /// ```dart
  /// Log.t('这是临时调试信息');  // 自动添加 TEMP 标签
  /// Log.t('调试变量', tag: 'MyFeature');  // 自定义标签
  /// ```
  static void t(
    dynamic message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DKLogLevel.temp,
      message,
      tag: tag ?? 'TEMP',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 通用日志方法
  static void _log(
    DKLogLevel level,
    dynamic message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled || level.value < _currentLevel.value) {
      return;
    }

    // 检查 tag 过滤
    if (_shouldFilterTag(tag)) {
      return;
    }

    final buffer = StringBuffer();

    // 添加颜色
    if (_useColor) {
      buffer.write(level.color);
    }

    // 添加时间戳 - 使用 <> 尖括号
    if (_showTimestamp) {
      final now = DateTime.now();
      buffer.write('<${_formatTime(now)}> ');
    }

    // 添加级别标签 - 保持使用 []
    buffer.write('[${level.label}]');

    // 添加自定义标签 - 使用 # 前缀
    if (tag != null && tag.isNotEmpty) {
      buffer.write(' #$tag');
    }

    // 添加调用位置 - 使用 @ 前缀
    if (_showLocation) {
      final location = _getCallerLocation();
      if (location.isNotEmpty) {
        buffer.write(' @$location');
      }
    }

    // 添加消息
    buffer.write(': $message');

    // 重置颜色
    if (_useColor) {
      buffer.write(_resetColor);
    }

    // 输出主日志
    debugPrint(buffer.toString());

    // 输出错误信息
    if (error != null) {
      debugPrint(
        '${_useColor ? level.color : ''}Error: $error${_useColor ? _resetColor : ''}',
      );
    }

    // 输出堆栈跟踪
    if (stackTrace != null) {
      debugPrint(
        '${_useColor ? level.color : ''}StackTrace:\n$stackTrace${_useColor ? _resetColor : ''}',
      );
    }

    // 写入日志文件（异步，不阻塞）
    if (_writeToFile && level.value >= _fileLogLevel.value) {
      final fileBuffer = StringBuffer();
      fileBuffer.write(buffer.toString());
      if (error != null) {
        fileBuffer.write('\nError: $error');
      }
      if (stackTrace != null) {
        fileBuffer.write('\nStackTrace:\n$stackTrace');
      }
      _writeToLogFile(fileBuffer.toString());
    }

    // 使用 developer.log 以便在 DevTools 中查看
    if (enableDeveloperLog) {
      developer.log(
        message.toString(),
        name: tag ?? 'DKLog',
        level: level.value * 1000,
        error: error,
        stackTrace: stackTrace,
      );
    }

    // 发送到 WebSocket 服务器
    if (_webSocketEnabled && level.value >= _webSocketLogLevel.value) {
      _sendToWebSocket(
        level: level,
        message: message.toString(),
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// 发送日志到 WebSocket
  static void _sendToWebSocket({
    required DKLogLevel level,
    required String message,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    try {
      final now = DateTime.now();
      final logData = {
        'timestamp': now.toIso8601String(),
        'timestampMs': now.millisecondsSinceEpoch,
        'level': level.label,
        'levelValue': level.value,
        'message': message,
        if (tag != null && tag.isNotEmpty) 'tag': tag,
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
        'location': _getCallerLocation(),
      };

      _webSocketClient.sendLog(logData);
    } catch (e) {
      // WebSocket 发送失败不影响正常日志
      debugPrint('[DKLog] WebSocket 发送失败: $e');
    }
  }

  /// 格式化时间
  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
  }

  /// 获取调用者位置（文件名和行号）
  static String _getCallerLocation() {
    try {
      final stackTrace = StackTrace.current.toString();
      final lines = stackTrace.split('\n');

      // 跳过日志类内部的调用栈
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // 跳过日志类本身的调用（支持 log.dart 和 dk_log.dart）
        if (!line.contains('dk_log.dart') &&
            !line.contains('StackTrace.current') &&
            line.contains('package:')) {
          // 提取文件名和行号
          // 支持两种格式：
          // 1. package:xxx/xxx.dart:123:45
          // 2. package:xxx/xxx.dart 123:45
          final match = RegExp(
            r'package:[^/]+/(.+?\.dart)[:\s]+(\d+)',
          ).firstMatch(line);
          if (match != null) {
            final file = match.group(1);
            final lineNumber = match.group(2);
            // 只显示文件名，不显示完整路径
            final fileName = file?.split('/').last ?? file;
            return '$fileName:$lineNumber';
          }
        }
      }
    } catch (e) {
      // 忽略错误
    }
    return '';
  }

  /// 打印分隔线
  static void separator({String char = '-', int length = 80}) {
    if (!_enabled) return;
    final line = char * length;
    debugPrint(line);

    // 写入日志文件
    if (_writeToFile) {
      _writeToLogFile(line);
    }
  }

  /// 打印 JSON 格式化输出
  static void json(dynamic jsonObject, {String? tag}) {
    if (!_enabled) return;
    try {
      final encoder = const JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(jsonObject);
      d('JSON Output:\n$prettyJson', tag: tag);
    } catch (error) {
      e('Failed to format JSON: $error', tag: tag);
    }
  }

  static void title(
    String title, {
    String char = '=',
    int length = 80,
    String? tag,
  }) {
    if (!_enabled) return;
    final separatorLine = char * length;

    debugPrint(separatorLine);
    debugPrint(title);
    debugPrint(separatorLine);

    // 写入日志文件
    if (_writeToFile) {
      final buffer = StringBuffer();
      buffer.writeln(separatorLine);
      buffer.writeln(title);
      buffer.write(separatorLine);
      _writeToLogFile(buffer.toString());
    }
  }
}
