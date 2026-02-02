import 'dart:async';

import 'package:dk_util/state/dk_state_event.dart';
import 'package:dk_util/state/dk_state_event_helper.dart';

/// Flutter 原生拓展
/// 适用于 StreamController<DKStateEvent<T>>
/// 提供触发事件和监听事件状态变化的便捷方法
/// 例如：
/// ```dart
/// final submitEvent = StreamController<DKStateEvent<void>>();
/// void submitData() {
///   submitEvent.triggerEvent(() async {
///     // 执行提交操作
///     await Future.delayed(Duration(seconds: 2));
///   });
/// }
/// submitEvent.listenEvent(
///   onLoading: () {
///     // 显示加载中
///   },
///   onSuccess: (data, message) {
///     // 处理成功
///   },
///   onError: (message, error, stackTrace) {
///     // 处理错误
///   },
/// );
/// ```
extension DKStateEventFlutterExtension<T> on StreamController<DKStateEvent<T>> {
  /// 触发事件并自动管理状态变化
  /// @param event 异步事件操作
  /// @return Future<void>
  Future<void> triggerEvent(Future<T> Function() event, {String? tag}) async {
    DKStateEventHelper.triggerEvent(
      onStateChange: (state) {
        add(state);
      },
      event: event,
      tag: tag,
    );
  }

  /// 监听事件状态变化并执行对应回调
  /// @param onLoading 加载中回调
  /// @param onSuccess 成功回调
  /// @param onError 错误回调
  /// @return StreamSubscription<DKStateEvent<T>>
  StreamSubscription<DKStateEvent<T>> listenEvent({
    void Function()? onLoading,
    void Function(T data)? onSuccess,
    void Function(String message, Object? error, StackTrace? stackTrack)?
    onError,
    void Function()? onIdle,
    void Function()? onComplete,
  }) {
    return stream.listen((state) {
      DKStateEventHelper.handleState(
        state,
        onLoading: onLoading,
        onSuccess: onSuccess,
        onError: onError,
        onIdle: onIdle,
        onComplete: onComplete,
      );
    });
  }
}
