
/// DKStateEvent - 用于一次性事件操作的状态管理
///
/// 适用场景：
/// - POST/PUT/DELETE 请求
/// - 提交操作（表单提交、按钮点击）
/// - 一次性事件（显示 Snackbar、导航跳转）
/// - 配合 StreamController 使用
///
/// 通用逻辑请使用：
/// - `DKStateEventHelper` 工具类提供的静态方法
/// - `DKStateEventFlutterExtension` 提供的扩展方法（用于 StreamController）
///
/// 例如：
/// ```dart
/// // 方式1: 使用扩展方法（推荐）
/// final submitEvent = StreamController<DKStateEvent<String>>();
///
/// submitEvent.triggerEvent(() async {
///   await Future.delayed(Duration(seconds: 2));
///   return 'Success';
/// });
///
/// final subscription = submitEvent.listenEvent(
///   onLoading: () => print('Loading...'),
///   onSuccess: (data, message) => print('Success: $data'),
///   onError: (message, error, stackTrace) => print('Error: $message'),
/// );
///
/// // 方式2: 使用工具类
/// await DKStateEventHelper.triggerEvent<String>(
///   onStateChange: (state) => controller.add(state),
///   event: () async => await fetchData(),
/// );
/// ```
sealed class DKStateEvent<T> {
  const DKStateEvent();
}

/// 状态：空闲
class DKStateEventIdle<T> extends DKStateEvent<T> {
  /// 运行 ID，用于日志追踪（可选）
  final String? runId;

  const DKStateEventIdle({this.runId});
}

/// 状态：加载中
class DKStateEventLoading<T> extends DKStateEvent<T> {
  /// 运行 ID，用于日志追踪
  final String runId;

  const DKStateEventLoading(this.runId);
}

/// 状态：成功
class DKStateEventSuccess<T> extends DKStateEvent<T> {
  /// 运行 ID，用于日志追踪
  final String runId;
  final T data;
  final String? message;

  const DKStateEventSuccess(this.runId, this.data, {this.message});
}

/// 状态：错误
class DKStateEventError<T> extends DKStateEvent<T> {
  /// 运行 ID，用于日志追踪
  final String runId;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const DKStateEventError(this.runId, this.message, {this.error, this.stackTrace});
}

class DkStateEventCompleted<T> extends DKStateEvent<T> {
  /// 运行 ID，用于日志追踪
  final String runId;

  const DkStateEventCompleted(this.runId);
}


