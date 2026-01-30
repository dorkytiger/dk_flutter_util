import 'dart:ui';

import 'package:dk_util/config/dk_config.dart';

class DKStateUtil {
  static void callLog(VoidCallback block) {
    if (DkConfig.showStateLog) {
      block();
    }
  }
}
