import 'dart:convert';

import 'package:dk_util/log/dk_log.dart';
import 'package:dk_util/state/dk_state_query.dart';
import 'package:dk_util/state/dk_state_util.dart';

class DKStateQueryHelper {
  DKStateQueryHelper._();

  static final _tag = 'DKStateQueryHelper';

  static Future<void> triggerQuery<T>({
    required Future<T> Function() query,
    bool Function(T data)? isEmpty,
    required void Function(DKStateQuery<T> state) onStateChange,
    String? tag,
  }) async {
    try {
      DKStateUtil.callLog(
        () => DKLog.title("开始查询数据: $T", tag: tag ?? _tag),
      );
      onStateChange(DkStateQueryLoading<T>());
      final result = await query();
      DKStateUtil.callLog(
        () => DKLog.d("查询数据成功: $T", tag: tag ?? _tag),
      );
      //尝试解析为Json以便更好地展示数据
      try {
        final encoder = const JsonEncoder.withIndent('  ');
        final prettyString = encoder.convert(result);
        DKStateUtil.callLog(
          () => DKLog.i("查询结果:\n$prettyString", tag:tag ?? _tag),
        );
      } catch (_) {
        DKStateUtil.callLog(
          () => DKLog.i("查询结果: $result", tag: tag ?? _tag),
        );
      }
      if (isEmpty != null && isEmpty(result)) {
        onStateChange(DkStateQueryEmpty<T>());
        DKStateUtil.callLog(
          () => DKLog.w("查询结果为空: $T", tag: tag ?? _tag),
        );
      } else {
        onStateChange(DkStateQuerySuccess<T>(result));
        DKStateUtil.callLog(
          () => DKLog.i("查询数据处理完成: $T", tag: tag ?? _tag),
        );
      }
    } catch (e, stackTrace) {
      onStateChange(DkStateQueryError<T>(e.toString()));
      DKStateUtil.callLog(
        () => DKLog.e(
          "查询数据出错: $e",
          tag: 'DKStateQueryHelper',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    } finally {
      DKStateUtil.callLog(
        () => DKLog.title("查询数据结束: $T", tag: 'DKStateQueryHelper'),
      );
    }
  }
}
