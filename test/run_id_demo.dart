import 'dart:async';
import 'package:dk_util/log/dk_log.dart';
import 'package:dk_util/state/dk_state_event.dart';
import 'package:dk_util/state/dk_state_event_flutter.dart';

/// 演示 runId 追踪功能
void main() async {
  DKLog.setLevel(DKLogLevel.debug);
  DKLog.separator(char: '=');
  DKLog.i('测试 RunID 追踪功能', tag: 'Test');
  DKLog.separator(char: '=');

  // 创建 StreamController
  final submitEvent = StreamController<DKStateEvent<String>>();

  // 监听事件（可以看到每个状态都有相同的 runId）
  final subscription = submitEvent.stream.listen((state) {
    if (state is DKStateEventLoading<String>) {
      DKLog.w('[${state.runId}] UI 收到：加载中状态', tag: 'UI');
    } else if (state is DKStateEventSuccess<String>) {
      DKLog.i('[${state.runId}] UI 收到：成功状态，数据: ${state.data}', tag: 'UI');
    } else if (state is DKStateEventError<String>) {
      DKLog.e('[${state.runId}] UI 收到：错误状态，消息: ${state.message}', tag: 'UI');
    }
  });

  // 测试 1: 成功的场景
  DKLog.separator();
  DKLog.i('开始测试 1：成功场景', tag: 'Test');
  await submitEvent.triggerEvent(() async {
    await Future.delayed(Duration(milliseconds: 500));
    return '提交成功的数据';
  }, tag: 'Submit');

  await Future.delayed(Duration(milliseconds: 200));

  // 测试 2: 失败的场景
  DKLog.separator();
  DKLog.i('开始测试 2：失败场景', tag: 'Test');
  await submitEvent.triggerEvent(() async {
    await Future.delayed(Duration(milliseconds: 500));
    throw Exception('提交失败：网络错误');
  }, tag: 'Submit');

  await Future.delayed(Duration(milliseconds: 200));

  // 测试 3: 并发多个任务，观察不同的 runId
  DKLog.separator();
  DKLog.i('开始测试 3：并发任务（观察不同的 runId）', tag: 'Test');

  final event1 = StreamController<DKStateEvent<String>>();
  final event2 = StreamController<DKStateEvent<String>>();
  final event3 = StreamController<DKStateEvent<String>>();

  event1.stream.listen((state) {
    if (state is DKStateEventSuccess<String>) {
      DKLog.i('[${state.runId}] 任务1 完成', tag: 'Task1');
    }
  });

  event2.stream.listen((state) {
    if (state is DKStateEventSuccess<String>) {
      DKLog.i('[${state.runId}] 任务2 完成', tag: 'Task2');
    }
  });

  event3.stream.listen((state) {
    if (state is DKStateEventSuccess<String>) {
      DKLog.i('[${state.runId}] 任务3 完成', tag: 'Task3');
    }
  });

  // 并发触发三个任务，每个任务有不同的 runId
  await Future.wait([
    event1.triggerEvent(() async {
      await Future.delayed(Duration(milliseconds: 300));
      return '任务1结果';
    }, tag: 'Task1'),
    event2.triggerEvent(() async {
      await Future.delayed(Duration(milliseconds: 200));
      return '任务2结果';
    }, tag: 'Task2'),
    event3.triggerEvent(() async {
      await Future.delayed(Duration(milliseconds: 100));
      return '任务3结果';
    }, tag: 'Task3'),
  ]);

  await Future.delayed(Duration(milliseconds: 100));

  // 清理
  await subscription.cancel();
  await submitEvent.close();
  await event1.close();
  await event2.close();
  await event3.close();

  DKLog.separator(char: '=');
  DKLog.i('测试完成', tag: 'Test');
  DKLog.separator(char: '=');

  print('\n');
  print('✅ RunID 追踪功能说明：');
  print('1. 每个任务都有唯一的 runId (格式: RUN_时间戳_随机数)');
  print('2. 同一个任务的所有状态（Loading -> Success/Error）共享相同的 runId');
  print('3. 不同任务有不同的 runId，方便在日志中区分');
  print('4. 在并发场景下，可以清晰地追踪每个任务的完整生命周期');
}
