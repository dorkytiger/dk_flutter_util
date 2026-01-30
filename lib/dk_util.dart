/// DK Util - DorkyTiger's Flutter Utility Library
///
/// 包含日志工具、状态管理等实用工具
library dk_util;

// ==================== 日志工具 ====================
export 'log/dk_log.dart';

// ==================== 状态管理 ====================
// 核心状态定义
export 'state/dk_state.dart';

// Event 状态管理（用于一次性事件）
export 'state/dk_state_event.dart';
export 'state/dk_state_event_helper.dart';
export 'state/dk_state_event_flutter.dart';

// Query 状态管理（用于数据查询）
export 'state/dk_state_query.dart';
export 'state/dk_state_query_flutter.dart';
