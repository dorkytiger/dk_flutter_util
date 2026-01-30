import 'dart:async';

import 'package:dk_util/log/dk_log.dart';
import 'package:dk_util/state/dk_state_event.dart';
import 'package:dk_util/state/dk_state_util.dart';

/// DKStateEvent 工具类 - 提供通用的状态管理逻辑
///
/// 这个类包含可复用的状态管理方法，可以被不同的状态管理方式使用：
/// - StreamController 扩展
/// - ValueNotifier 扩展
/// - 其他自定义状态管理
class DKStateEventHelper {
  DKStateEventHelper._();

  static final String _tag = 'DKStateEventHelper';

  /// 触发事件并自动管理状态变化
  ///
  /// 这是一个通用的事件触发逻辑，会自动处理：
  /// - 生成唯一的运行 ID 用于日志追踪
  /// - 发送 Loading 状态
  /// - 执行异步操作
  /// - 发送 Success 或 Error 状态
  /// - 记录日志
  ///
  /// @param onStateChange 状态变化回调，用于发送新状态
  /// @param event 异步事件操作
  /// @param tag 日志标签（可选）
  /// @return Future<void>
  ///
  /// 示例：
  /// ```dart
  /// await DKStateEventHelper.triggerEvent<String>(
  ///   onStateChange: (state) => controller.add(state),
  ///   event: () async => await fetchData(),
  ///   tag: 'FetchData',
  /// );
  /// ```
  static Future<void> triggerEvent<T>({
    required void Function(DKStateEvent<T> state) onStateChange,
    required Future<T> Function() event,
    String? tag,
  }) async {
    // 生成唯一的运行 ID
    final runId = _generateRunId();
    final logTag = tag ?? _tag;

    try {
      DKStateUtil.callLog(
            () => DKLog.title("[$runId] 开始处理事件: $T", tag: logTag),
      );
      DKStateUtil.callLog(DKLog.separator);
      DKStateUtil.callLog(() => DKLog.d("[$runId] 触发事件: $T", tag: logTag));

      // 发送加载中状态
      onStateChange(DKStateEventLoading<T>(runId));

      // 执行异步操作
      final result = await event();

      // 发送成功状态
      onStateChange(DKStateEventSuccess<T>(runId, result));
      DKStateUtil.callLog(() =>
          DKLog.i("[$runId] 事件成功完成: $T", tag: logTag));

      // 记录结果（如果需要）
      if (result != null) {
        try {
          DKStateUtil.callLog(() => DKLog.json(result, tag: logTag));
        } catch (_) {
          // JSON 序列化失败时忽略
          DKStateUtil.callLog(
                () => DKLog.d("[$runId] 结果: $result", tag: logTag),
          );
        }
      }
    } catch (e, stackTrace) {
      // 发送错误状态
      final errorMessage = e.toString();
      onStateChange(
        DKStateEventError<T>(
          runId,
          errorMessage,
          error: e,
          stackTrace: stackTrace,
        ),
      );
      DKStateUtil.callLog(
            () =>
            DKLog.e(
              "[$runId] 事件执行出错: $errorMessage",
              tag: logTag,
              error: e,
              stackTrace: stackTrace,
            ),
      );
    } finally {
      onStateChange(DkStateEventCompleted<T>(runId));
      DKStateUtil.callLog(() {
        DKLog.d("[$runId] 事件处理完成: $T", tag: logTag);
      });
      DKStateUtil.callLog(DKLog.separator);
      DKStateUtil.callLog(
            () => DKLog.title("[$runId] 结束处理事件: $T", tag: logTag),
      );
    }
  }

  /// 生成唯一的运行 ID
  /// 格式：RUN_时间戳_随机数
  static String _generateRunId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    // 使用微秒的后4位作为随机数，增加唯一性
    final random = (now.microsecondsSinceEpoch % 10000).toString().padLeft(
      4,
      '0',
    );
    return 'RUN_${timestamp}_$random';
  }

  /// 处理单个状态事件并执行对应回调
  ///
  /// 这是一个通用的状态处理逻辑，根据状态类型执行不同的回调
  ///
  /// @param state 当前状态
  /// @param onLoading 加载中回调
  /// @param onSuccess 成功回调
  /// @param onError 错误回调
  /// @return Future<void>
  ///
  /// 示例：
  /// ```dart
  /// await DKStateEventHelper.handleState(
  ///   currentState,
  ///   onLoading: () => showLoading(),
  ///   onSuccess: (data, message) => showData(data),
  ///   onError: (message, error, stackTrace) => showError(message),
  ///
  /// );
  /// ```
  static Future<void> handleState<T>(DKStateEvent<T> state, {
    void Function()? onLoading,
    void Function(T data, String message)? onSuccess,
    void Function(String message, Object? error, StackTrace? stackTrace)?
    onError,
    void Function()? onIdle,
    void Function()? onComplete,
  }) async {
    if (state is DKStateEventLoading<T>) {
      if (onLoading != null) {
        DKStateUtil.callLog(
              () => DKLog.d("[${state.runId}] 状态：加载中", tag: _tag),
        );
        try {
          DKStateUtil.callLog(() =>
              DKLog.i("[${state.runId}] 开始执行加载中回调", tag: _tag));
          onLoading();
          DKStateUtil.callLog(
                () => DKLog.i("[${state.runId}] 加载中回调执行完毕", tag: _tag),
          );
        } catch (e, stackTrace) {
          DKStateUtil.callLog(
                () =>
                DKLog.e(
                  "[${state.runId}] 加载中回调出错: $e",
                  tag: _tag,
                  error: e,
                  stackTrace: stackTrace,
                ),
          );
        } finally {
          DKStateUtil.callLog(() =>
              DKLog.i("[${state.runId}] 结束执行加载中回调", tag: _tag));
        }
      }
    } else if (state is DKStateEventSuccess<T>) {
      if (onSuccess != null) {
        DKStateUtil.callLog(() =>
            DKLog.i("[${state.runId}] 状态：成功", tag: _tag));
        try {
          DKStateUtil.callLog(() =>
              DKLog.i("[${state.runId}] 开始执行成功回调", tag: _tag));
          onSuccess(state.data, "操作成功");
          DKStateUtil.callLog(
                () => DKLog.i("[${state.runId}] 成功回调执行完毕", tag: _tag),
          );
        } catch (e, stackTrace) {
          DKStateUtil.callLog(
                () =>
                DKLog.e(
                  "[${state.runId}] 成功回调出错: $e",
                  tag: _tag,
                  error: e,
                  stackTrace: stackTrace,
                ),
          );
        } finally {
          DKStateUtil.callLog(() =>
              DKLog.i("[${state.runId}] 结束执行成功回调", tag: _tag));
        }
      }
    } else if (state is DKStateEventError<T>) {
      if (onError != null) {
        DKStateUtil.callLog(
              () =>
              DKLog.e(
                  "[${state.runId}] 状态：错误 - ${state.message}", tag: _tag),
        );
        try {
          DKStateUtil.callLog(() =>
              DKLog.i("[${state.runId}] 开始执行错误回调", tag: _tag));
          onError(state.message, state.error, state.stackTrace);
          DKStateUtil.callLog(
                () => DKLog.i("[${state.runId}] 错误回调执行完毕", tag: _tag),
          );
        } catch (e, stackTrace) {
          DKStateUtil.callLog(
                () =>
                DKLog.e(
                  "[${state.runId}] 错误回调出错: $e",
                  tag: _tag,
                  error: e,
                  stackTrace: stackTrace,
                ),
          );
        } finally {
          DKStateUtil.callLog(() =>
              DKLog.i("[${state.runId}] 结束执行错误回调", tag: _tag));
        }
      } else if (state is DKStateEventIdle<T>) {
        if (onIdle != null) {
          DKStateUtil.callLog(
                () => DKLog.d("[${state.runId ?? 'N/A'}] 状态：空闲", tag: _tag),
          );
          try {
            DKStateUtil.callLog(() =>
                DKLog.i(
                    "[${state.runId ?? 'N/A'}] 开始执行空闲回调", tag: _tag));
            onIdle();
            DKStateUtil.callLog(
                  () =>
                  DKLog.i(
                    "[${state.runId ?? 'N/A'}] 空闲回调执行完毕",
                    tag: _tag,
                  ),
            );
          } catch (e, stackTrace) {
            DKStateUtil.callLog(
                  () =>
                  DKLog.e(
                    "[${state.runId ?? 'N/A'}] 空闲回调出错: $e",
                    tag: _tag,
                    error: e,
                    stackTrace: stackTrace,
                  ),
            );
          } finally {
            DKStateUtil.callLog(() =>
                DKLog.i(
                    "[${state.runId ?? 'N/A'}] 结束执行空闲回调", tag: _tag));
          }
        } else if (state is DkStateEventCompleted<T>) {
          if (onComplete != null) {
            DKStateUtil.callLog(() =>
                DKLog.d("[${state.runId}] 状态：完成", tag: _tag));
            try {
              DKStateUtil.callLog(() =>
                  DKLog.i("[${state.runId}] 开始执行完成回调", tag: _tag));
              onComplete();
              DKStateUtil.callLog(
                    () =>
                    DKLog.i("[${state.runId}] 完成回调执行完毕", tag: _tag),
              );
            } catch (e, stackTrace) {
              DKStateUtil.callLog(
                    () =>
                    DKLog.e(
                      "[${state.runId}] 完成回调出错: $e",
                      tag: _tag,
                      error: e,
                      stackTrace: stackTrace,
                    ),
              );
            } finally {
              DKStateUtil.callLog(() =>
                  DKLog.i("[${state.runId}] 结束执行完成回调", tag: _tag));
            }
          }
        }
      }
    }
  }
}