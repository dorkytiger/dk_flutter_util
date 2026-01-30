import 'package:dk_util/log/dk_log.dart';

void main() {
  DKLog.d('调试信息');
  DKLog.i('普通信息');
  DKLog.w('警告信息');
  DKLog.e('错误信息');
  DKLog.separator();
  DKLog.i('测试完成', tag: 'Test');
}
