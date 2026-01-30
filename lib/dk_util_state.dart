/// DK Util - 状态管理模块
///
/// 只导入状态管理相关功能
library dk_util_state;

// 核心状态定义
export 'state/dk_state.dart';

// Event 状态管理（用于一次性事件）
export 'state/dk_state_event.dart';
export 'state/dk_state_event_helper.dart';
export 'state/dk_state_event_flutter.dart';

// Query 状态管理（用于数据查询）
export 'state/dk_state_query.dart';
export 'state/dk_state_query_flutter.dart';
