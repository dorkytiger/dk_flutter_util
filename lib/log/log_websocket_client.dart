import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket 日志客户端
/// 通过 mDNS 服务发现连接到电脑端的日志服务器
class LogWebSocketClient {
  LogWebSocketClient._();

  static final LogWebSocketClient _instance = LogWebSocketClient._();
  static LogWebSocketClient get instance => _instance;

  /// WebSocket 连接
  WebSocketChannel? _channel;

  /// 是否已启用
  bool _enabled = false;

  /// 是否已连接
  bool _connected = false;

  /// mDNS 服务发现
  Discovery? _discovery;

  /// 服务类型（可自定义）
  static const String _serviceType = '_hurricane-log._tcp';

  /// 重连定时器
  Timer? _reconnectTimer;

  /// 重连间隔（秒）
  static const int _reconnectInterval = 5;

  /// 连接超时时间（秒）
  static const int _connectionTimeout = 10;

  /// 服务器地址（如果手动指定）
  String? _manualHost;
  int? _manualPort;
  String? _manualPath;

  /// 是否正在连接
  bool _connecting = false;

  /// 消息队列（连接断开时缓存消息）
  final List<Map<String, dynamic>> _messageQueue = [];

  /// 最大队列大小
  static const int _maxQueueSize = 100;

  /// 连接状态回调
  void Function(bool connected)? onConnectionStatusChanged;

  /// 是否已启用
  bool get isEnabled => _enabled;

  /// 是否已连接
  bool get isConnected => _connected;

  /// 启用 WebSocket 日志传输
  ///
  /// [autoDiscover] - 是否自动通过 mDNS 发现服务器（默认 true）
  /// [host] - 手动指定服务器地址（如果不使用自动发现）
  /// [port] - 手动指定服务器端口（如果不使用自动发现）
  /// [path] - WebSocket 路径（默认为空，例如 '/logs'）
  /// [serviceName] - mDNS 服务名称（可选，用于指定特定服务器）
  Future<void> enable({
    bool autoDiscover = true,
    String? host,
    int? port,
    String? path,
    String? serviceName,
  }) async {
    if (_enabled) {
      debugPrint('[LogWebSocket] 已经启用，跳过');
      return;
    }

    _enabled = true;
    debugPrint('[LogWebSocket] 启用 WebSocket 日志传输');

    if (autoDiscover) {
      await _startServiceDiscovery(serviceName: serviceName);
    } else if (host != null && port != null) {
      _manualHost = host;
      _manualPort = port;
      _manualPath = path;
      await _connect(host, port, path: path);
    } else {
      debugPrint('[LogWebSocket] 错误：必须启用自动发现或手动指定服务器地址');
      _enabled = false;
    }
  }

  /// 禁用 WebSocket 日志传输
  Future<void> disable() async {
    if (!_enabled) {
      return;
    }

    debugPrint('[LogWebSocket] 禁用 WebSocket 日志传输');
    _enabled = false;

    await _disconnect();
    await _stopServiceDiscovery();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _messageQueue.clear();
  }

  /// 开始 mDNS 服务发现
  Future<void> _startServiceDiscovery({String? serviceName}) async {
    if (kIsWeb) {
      debugPrint('[LogWebSocket] Web 平台不支持 mDNS 服务发现');
      return;
    }

    try {
      debugPrint('[LogWebSocket] 开始 mDNS 服务发现: $_serviceType');

      _discovery = await startDiscovery(_serviceType);

      _discovery!.addServiceListener((service, status) async {
        debugPrint('[LogWebSocket] 发现服务: ${service.name} - $status');

        if (status == ServiceStatus.found) {
          // 如果指定了服务名称，只连接匹配的服务
          if (serviceName != null && service.name != serviceName) {
            debugPrint('[LogWebSocket] 跳过服务：${service.name}（不匹配）');
            return;
          }

          // 解析服务信息
          final resolvedService = await resolve(service);
          final host = resolvedService.host;
          final port = resolvedService.port;

          if (host != null && port != null) {
            debugPrint('[LogWebSocket] 解析服务成功: $host:$port');
            await _connect(host, port);
          } else {
            debugPrint('[LogWebSocket] 服务解析失败：缺少 host 或 port');
          }
                } else if (status == ServiceStatus.lost) {
          debugPrint('[LogWebSocket] 服务丢失: ${service.name}');
          if (_connected) {
            await _disconnect();
            _startReconnect();
          }
        }
      });
    } catch (e, stackTrace) {
      debugPrint('[LogWebSocket] 服务发现失败: $e');
      debugPrint('[LogWebSocket] StackTrace: $stackTrace');
    }
  }

  /// 停止 mDNS 服务发现
  Future<void> _stopServiceDiscovery() async {
    if (_discovery != null) {
      try {
        await stopDiscovery(_discovery!);
        _discovery = null;
        debugPrint('[LogWebSocket] 停止服务发现');
      } catch (e) {
        debugPrint('[LogWebSocket] 停止服务发现失败: $e');
      }
    }
  }

  /// 连接到服务器
  Future<void> _connect(String host, int port, {String? path}) async {
    if (_connecting) {
      debugPrint('[LogWebSocket] 正在连接中，跳过');
      return;
    }

    if (_connected) {
      debugPrint('[LogWebSocket] 已经连接，跳过');
      return;
    }

    _connecting = true;

    try {
      // 构建 WebSocket URL
      final pathSegment = path ?? '';
      final url = 'ws://$host:$port$pathSegment';
      debugPrint('[LogWebSocket] 正在连接到 $url');

      final uri = Uri.parse(url);

      // 使用超时控制
      final channel = IOWebSocketChannel.connect(
        uri,
        connectTimeout: const Duration(seconds: _connectionTimeout),
      );

      // 等待连接建立
      await channel.ready.timeout(
        const Duration(seconds: _connectionTimeout),
        onTimeout: () {
          throw TimeoutException('连接超时');
        },
      );

      _channel = channel;
      _connected = true;
      _connecting = false;

      debugPrint('[LogWebSocket] 连接成功: $url');
      onConnectionStatusChanged?.call(true);

      // 发送缓存的消息
      _flushMessageQueue();

      // 监听连接关闭
      _channel!.stream.listen(
        (message) {
          // 可以接收服务器的响应消息（如果需要）
          debugPrint('[LogWebSocket] 收到消息: $message');
        },
        onDone: () {
          debugPrint('[LogWebSocket] 连接关闭');
          _onDisconnected();
        },
        onError: (error) {
          debugPrint('[LogWebSocket] 连接错误: $error');
          _onDisconnected();
        },
        cancelOnError: true,
      );
    } catch (e, stackTrace) {
      debugPrint('[LogWebSocket] 连接失败: $e');
      debugPrint('[LogWebSocket] StackTrace: $stackTrace');
      _connecting = false;
      _onDisconnected();
    }
  }

  /// 断开连接
  Future<void> _disconnect() async {
    if (_channel != null) {
      try {
        await _channel!.sink.close();
        debugPrint('[LogWebSocket] 主动断开连接');
      } catch (e) {
        debugPrint('[LogWebSocket] 断开连接失败: $e');
      }
      _channel = null;
    }

    _connected = false;
    _connecting = false;
    onConnectionStatusChanged?.call(false);
  }

  /// 连接断开时的处理
  void _onDisconnected() {
    _connected = false;
    _connecting = false;
    _channel = null;
    onConnectionStatusChanged?.call(false);

    // 如果启用了自动重连
    if (_enabled) {
      _startReconnect();
    }
  }

  /// 开始重连
  void _startReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return;
    }

    debugPrint('[LogWebSocket] 将在 $_reconnectInterval 秒后重连');

    _reconnectTimer = Timer.periodic(
      const Duration(seconds: _reconnectInterval),
      (timer) async {
        if (!_enabled) {
          timer.cancel();
          return;
        }

        if (_connected || _connecting) {
          timer.cancel();
          return;
        }

        debugPrint('[LogWebSocket] 尝试重连...');

        if (_manualHost != null && _manualPort != null) {
          await _connect(_manualHost!, _manualPort!, path: _manualPath);
        } else {
          // 如果是通过服务发现，需要重新发现
          await _stopServiceDiscovery();
          await _startServiceDiscovery();
        }
      },
    );
  }

  /// 发送日志消息
  void sendLog(Map<String, dynamic> logData) {
    if (!_enabled) {
      return;
    }

    if (!_connected || _channel == null) {
      // 缓存消息
      _queueMessage(logData);
      return;
    }

    try {
      final jsonString = jsonEncode(logData);
      _channel!.sink.add(jsonString);
    } catch (e) {
      debugPrint('[LogWebSocket] 发送日志失败: $e');
      _queueMessage(logData);
    }
  }

  /// 缓存消息到队列
  void _queueMessage(Map<String, dynamic> logData) {
    if (_messageQueue.length >= _maxQueueSize) {
      // 移除最旧的消息
      _messageQueue.removeAt(0);
    }
    _messageQueue.add(logData);
    debugPrint('[LogWebSocket] 消息已缓存，队列大小: ${_messageQueue.length}');
  }

  /// 发送队列中的所有消息
  void _flushMessageQueue() {
    if (_messageQueue.isEmpty) {
      return;
    }

    debugPrint('[LogWebSocket] 发送缓存的 ${_messageQueue.length} 条消息');

    for (final logData in _messageQueue) {
      try {
        final jsonString = jsonEncode(logData);
        _channel?.sink.add(jsonString);
      } catch (e) {
        debugPrint('[LogWebSocket] 发送缓存消息失败: $e');
      }
    }

    _messageQueue.clear();
  }

  /// 手动重连（用于用户界面）
  Future<void> reconnect() async {
    if (_connected) {
      await _disconnect();
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_manualHost != null && _manualPort != null) {
      await _connect(_manualHost!, _manualPort!, path: _manualPath);
    } else {
      await _stopServiceDiscovery();
      await _startServiceDiscovery();
    }
  }
}
