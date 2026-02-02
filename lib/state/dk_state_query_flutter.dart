import 'package:dk_util/state/dk_state_query.dart';
import 'package:dk_util/state/dk_state_query_helper.dart';
import 'package:flutter/cupertino.dart';

///flutter原生拓展
///适用于 ValueNotifier<DkStateQuery<T>>
///提供将 DkStateQuery 转换为 Flutter Widget 显示的便捷方法
///例如：
///```dart
///final stateNotifier = ValueNotifier<DkStateQuery<List<String>>>(DkStateQueryIdle());
///...
///Widget build(BuildContext context) {
///  return stateNotifier.displayDkStateQuery(
///    loadingBuilder: () => CircularProgressIndicator(),
///    errorBuilder: (message) => Text('Error: $message'),
///    emptyBuilder: () => Text('No Data'),
///    initialBuilder: () => Text('Please start loading'),
///    successBuilder: (data) => ListView(
///      children: data.map((item) => ListTile(title: Text(item))).toList(),
///    ),
///  );
///}
///```
extension DkStateQueryFlutterExtension<T> on ValueNotifier<DKStateQuery<T>> {
  /// 将 DkStateQuery 转换为 Flutter Widget 显示
  /// @param loadingBuilder 加载中状态的 Widget 构建器
  /// @param errorBuilder 错误状态的 Widget 构建器，接收错误信息
  /// @param emptyBuilder 空数据状态的 Widget 构建器
  /// @param initialBuilder 初始状态的 Widget 构建器
  /// @param successBuilder 成功状态的 Widget 构建器，接收数据
  /// @param retryBuilder 重试按钮的 Widget 构建器
  /// @return Widget 根据当前状态构建的 Widget
  Widget display({
    Widget Function()? loadingBuilder,
    Widget Function(String message)? errorBuilder,
    Widget Function()? emptyBuilder,
    Widget Function()? initialBuilder,
    required Widget Function(T data) successBuilder,
    Widget Function()? retryBuilder,
  }) {
    return ValueListenableBuilder<DKStateQuery<T>>(
      valueListenable: this,
      builder: (context, state, _) {
        return DKStateQueryDisplay(
          state: state,
          loadingBuilder: loadingBuilder,
          errorBuilder: errorBuilder,
          emptyBuilder: emptyBuilder,
          initialBuilder: initialBuilder,
          successBuilder: successBuilder,
        );
      },
    );
  }

  /// 执行查询并更新状态
  /// @param query 异步查询函数，返回数据
  /// @param isEmpty 可选的空数据判断函数
  /// @return Future<void>
  Future<void> query({
    required Future<T> Function() query,
    bool Function(T data)? isEmpty,
  }) async {
    await DKStateQueryHelper.triggerQuery<T>(
      query: query,
      isEmpty: isEmpty,
      onStateChange: (state) => value = state,
    );
  }
}
