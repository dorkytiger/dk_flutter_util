import 'dart:async';
import 'package:dk_util/log/dk_log.dart';
import 'package:dk_util/state/dk_state_event.dart';
import 'package:dk_util/state/dk_state_event_flutter.dart';

void main() async {
  DKLog.separator(char: '=');
  DKLog.i('测试 DKStateEvent Flutter 扩展', tag: 'Test');
  DKLog.separator(char: '=');

  // 创建 StreamController
  final submitEvent = StreamController<DKStateEvent<String>>();

  // 监听事件
  final subscription = submitEvent.listenEvent(
    onLoading: () {
      DKLog.w('状态：加载中...', tag: 'StateChange');
    },
    onSuccess: (data) {
      DKLog.i('状态：成功! 数据: $data', tag: 'StateChange');
    },
    onError: (message, error, stackTrace) {
      DKLog.e('状态：错误! $message', tag: 'StateChange');
    },
  );

  // 测试成功的场景
  DKLog.separator();
  DKLog.i('开始测试：成功场景', tag: 'Test');
  await submitEvent.triggerEvent(() async {
    await Future.delayed(Duration(milliseconds: 500));
    return '提交成功';
  });

  await Future.delayed(Duration(milliseconds: 100));

  // 测试失败的场景
  DKLog.separator();
  DKLog.i('开始测试：失败场景', tag: 'Test');
  await submitEvent.triggerEvent(() async {
    await Future.delayed(Duration(milliseconds: 500));
    throw Exception('提交失败：网络错误');
  });

  await Future.delayed(Duration(milliseconds: 100));

  // 清理
  await subscription.cancel();
  await submitEvent.close();

  DKLog.separator(char: '=');
  DKLog.i('测试完成', tag: 'Test');
  DKLog.separator(char: '=');
}
