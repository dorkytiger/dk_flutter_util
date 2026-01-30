import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// DkStateQuery - 用于 GET 查询操作的状态管理
/// 适用场景：
/// - GET 请求（列表、详情）
/// - 页面数据加载
/// - 需要保持状态的场景
/// - 配合 状态管理 使用
/// 特点：
/// - 状态持久化（配置重建后恢复）
/// - 全量 UI 渲染
/// - 适合 Display() 组件展示
sealed class DKStateQuery<T> {
  const DKStateQuery();

  bool get isLoading => this is DkStateQueryLoading;

  bool get isIdle => this is DkStateQueryIdle;

  bool get isSuccess => this is DkStateQuerySuccess<T>;

  bool get isEmpty => this is DkStateQueryEmpty;

  bool get isError => this is DkStateQueryError;

  T get data =>
      this is DkStateQuerySuccess<T>
          ? (this as DkStateQuerySuccess<T>).data
          : throw DkStateQueryException('No data available');

  String get errorMessage =>
      this is DkStateQueryError
          ? (this as DkStateQueryError).errorMessage
          : throw DkStateQueryException('No error message available');



}

/// 空闲状态 - 初始状态
class DkStateQueryIdle<T> extends DKStateQuery<T> {
  const DkStateQueryIdle();
}

/// 加载中状态
class DkStateQueryLoading<T> extends DKStateQuery<T> {
  const DkStateQueryLoading();
}

/// 成功状态
class DkStateQuerySuccess<T> extends DKStateQuery<T> {
  @override
  final T data;

  const DkStateQuerySuccess(this.data);
}

class DkStateQueryEmpty<T> extends DKStateQuery<T> {
  const DkStateQueryEmpty();
}

/// 错误状态
class DkStateQueryError<T> extends DKStateQuery<T> {
  @override
  final String errorMessage;

  const DkStateQueryError(this.errorMessage);
}

class DkStateQueryException implements Exception {
  final String message;

  DkStateQueryException(this.message);

  @override
  String toString() => 'DkStateQueryException: $message';
}

class DkStateQueryExtensions {
  static DKStateQuery<T> idle<T>() => DkStateQueryIdle<T>();

  static DKStateQuery<T> loading<T>() => DkStateQueryLoading<T>();

  static DKStateQuery<T> success<T>(T data) => DkStateQuerySuccess<T>(data);

  static DKStateQuery<T> empty<T>() => DkStateQueryEmpty<T>();

  static DKStateQuery<T> error<T>(String message) =>
      DkStateQueryError<T>(message);
}

class DKStateQueryDisplay<T> extends StatelessWidget {
  final DKStateQuery<T> state;
  final Widget Function()? initialBuilder;
  final Widget Function()? loadingBuilder;
  final Widget Function(String message)? errorBuilder;
  final Widget Function()? emptyBuilder;
  final Widget Function(T data) successBuilder;
  final Widget Function()? retryBuilder;
  final VoidCallback? onRetry;
  final Duration transitionDuration;
  final Color? backgroundColor;

  const DKStateQueryDisplay({
    super.key,
    required this.state,
    this.initialBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    required this.successBuilder,
    this.retryBuilder,
    this.onRetry,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: transitionDuration,
      child: _buildChild(context),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (state.isIdle) {
      return initialBuilder != null
          ? initialBuilder!.call()
          : SizedBox.shrink();
    } else if (state.isLoading) {
      return loadingBuilder != null
          ? loadingBuilder!.call()
          : Center(child: CupertinoActivityIndicator());
    } else if (state.isSuccess) {
      return successBuilder(state.data);
    } else if (state.isEmpty) {
      return emptyBuilder != null
          ? emptyBuilder!.call()
          : Center(child: Text('No Data Available'));
    } else if (state.isError) {
      return errorBuilder != null
          ? errorBuilder!(state.errorMessage)
          : Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: ${state.errorMessage}'),
            SizedBox(height: 16),
            if (onRetry != null)
              retryBuilder != null
                  ? retryBuilder!.call()
                  : ElevatedButton(
                onPressed: onRetry,
                child: Text('Retry'),
              ),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }
}
