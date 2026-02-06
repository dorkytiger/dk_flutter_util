import 'dart:async';

import 'package:dk_util/dk_util_state.dart';
import 'package:flutter/material.dart';

/// DKState 使用示例
///
/// 本文件包含 DKStateQuery 和 DKStateEvent 两种状态管理方式的完整使用示例

// ==============================================================================
// 示例页面 - 展示 State 完整用法
// ==============================================================================

/// 示例数据模型
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  @override
  String toString() => 'User(id: $id, name: $name)';
}

/// 模拟 API 服务
class MockApiService {
  /// 模拟获取用户列表（GET 请求）
  static Future<List<User>> fetchUsers() async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      User(id: 1, name: '张三', email: 'zhangsan@example.com'),
      User(id: 2, name: '李四', email: 'lisi@example.com'),
      User(id: 3, name: '王五', email: 'wangwu@example.com'),
    ];
  }

  /// 模拟获取用户详情（GET 请求）
  static Future<User> fetchUserById(int id) async {
    await Future.delayed(const Duration(seconds: 1));
    return User(id: id, name: '用户$id', email: 'user$id@example.com');
  }

  /// 模拟创建用户（POST 请求）
  static Future<User> createUser(String name, String email) async {
    await Future.delayed(const Duration(seconds: 2));
    if (name.isEmpty) {
      throw Exception('用户名不能为空');
    }
    return User(id: DateTime.now().millisecondsSinceEpoch, name: name, email: email);
  }

  /// 模拟删除用户（DELETE 请求）
  static Future<void> deleteUser(int id) async {
    await Future.delayed(const Duration(seconds: 1));
    if (id <= 0) {
      throw Exception('无效的用户ID');
    }
  }

  /// 模拟更新用户（PUT 请求）
  static Future<User> updateUser(User user) async {
    await Future.delayed(const Duration(seconds: 1));
    return user;
  }
}

// ==============================================================================
// 示例 1: DKStateQuery - 用于 GET 查询操作
// ==============================================================================

/// DKStateQuery 使用示例
///
/// 适用场景：
/// - GET 请求（列表、详情）
/// - 页面数据加载
/// - 需要保持状态的场景
class StateQueryExample extends StatefulWidget {
  const StateQueryExample({super.key});

  @override
  State<StateQueryExample> createState() => _StateQueryExampleState();
}

class _StateQueryExampleState extends State<StateQueryExample> {
  /// 用户列表状态
  final usersState = ValueNotifier<DKStateQuery<List<User>>>(
    DkStateQueryIdle(),
  );

  /// 用户详情状态
  final userDetailState = ValueNotifier<DKStateQuery<User>>(
    DkStateQueryIdle(),
  );

  /// 加载用户列表
  void _fetchUsers() {
    usersState.query(
      query: () => MockApiService.fetchUsers(),
      // 可选：自定义空数据判断
      isEmpty: (data) => data.isEmpty,
    );
  }

  /// 加载用户详情
  void _fetchUserDetail(int userId) {
    userDetailState.query(
      query: () => MockApiService.fetchUserById(userId),
    );
  }

  @override
  void initState() {
    super.initState();
    // 页面初始化时加载数据
    _fetchUsers();
  }

  @override
  void dispose() {
    usersState.dispose();
    userDetailState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DKStateQuery 示例'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // 用户列表
          Expanded(
            flex: 2,
            child: usersState.display(
              // 可选：自定义加载状态
              loadingBuilder: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('加载用户列表中...'),
                  ],
                ),
              ),
              // 可选：自定义错误状态
              errorBuilder: (message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('加载失败: $message'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchUsers,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
              // 可选：自定义空数据状态
              emptyBuilder: () => const Center(
                child: Text('暂无用户数据'),
              ),
              // 可选：自定义初始状态
              initialBuilder: () => const Center(
                child: Text('点击刷新按钮加载数据'),
              ),
              // 必须：成功状态构建器
              successBuilder: (users) => ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${user.id}')),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    onTap: () => _fetchUserDetail(user.id),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          // 用户详情
          Expanded(
            flex: 1,
            child: userDetailState.display(
              initialBuilder: () => const Center(
                child: Text('点击列表项查看详情'),
              ),
              successBuilder: (user) => Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('用户详情', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('ID: ${user.id}'),
                      Text('姓名: ${user.name}'),
                      Text('邮箱: ${user.email}'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 示例 2: DKStateEvent - 用于一次性事件操作
// ==============================================================================

/// DKStateEvent 使用示例
///
/// 适用场景：
/// - POST/PUT/DELETE 请求
/// - 提交操作（表单提交、按钮点击）
/// - 一次性事件（显示 Snackbar、导航跳转）
class StateEventExample extends StatefulWidget {
  const StateEventExample({super.key});

  @override
  State<StateEventExample> createState() => _StateEventExampleState();
}

class _StateEventExampleState extends State<StateEventExample> {
  /// 创建用户事件
  final createUserEvent = StreamController<DKStateEvent<User>>();

  /// 删除用户事件
  final deleteUserEvent = StreamController<DKStateEvent<void>>();

  /// 事件订阅
  late final StreamSubscription<DKStateEvent<User>> _createSubscription;
  late final StreamSubscription<DKStateEvent<void>> _deleteSubscription;

  /// 表单控制器
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  /// 是否正在提交
  bool _isSubmitting = false;

  /// 创建用户
  void _createUser() {
    createUserEvent.triggerEvent(
      () => MockApiService.createUser(
        _nameController.text,
        _emailController.text,
      ),
      tag: 'CreateUser', // 可选：用于日志追踪
    );
  }

  /// 删除用户
  void _deleteUser(int userId) {
    deleteUserEvent.triggerEvent(
      () => MockApiService.deleteUser(userId),
      tag: 'DeleteUser',
    );
  }

  @override
  void initState() {
    super.initState();

    // 监听创建用户事件
    _createSubscription = createUserEvent.listenEvent(
      onLoading: () {
        setState(() => _isSubmitting = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('正在创建用户...'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      onSuccess: (user) {
        setState(() => _isSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('用户 ${user.name} 创建成功'),
              backgroundColor: Colors.green,
            ),
          );
          // 清空表单
          _nameController.clear();
          _emailController.clear();
        }
      },
      onError: (message, error, stackTrace) {
        setState(() => _isSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('创建失败: $message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      onComplete: () {
        // 可选：无论成功失败都会调用
        debugPrint('创建操作完成');
      },
    );

    // 监听删除用户事件
    _deleteSubscription = deleteUserEvent.listenEvent(
      onLoading: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('正在删除...')),
          );
        }
      },
      onSuccess: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('删除成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      onError: (message, error, stackTrace) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败: $message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _createSubscription.cancel();
    _deleteSubscription.cancel();
    createUserEvent.close();
    deleteUserEvent.close();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DKStateEvent 示例'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 创建用户表单
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '创建新用户',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '用户名',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: '邮箱',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _createUser,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('创建用户'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 删除用户示例
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '删除用户示例',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _deleteUser(1),
                            icon: const Icon(Icons.delete),
                            label: const Text('删除用户 1'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _deleteUser(-1), // 会触发错误
                            icon: const Icon(Icons.error),
                            label: const Text('删除无效ID'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 示例 3: 组合使用 - Query + Event
// ==============================================================================

/// 组合使用示例
///
/// 展示如何在同一页面中同时使用 Query（加载数据）和 Event（提交操作）
class CombinedStateExample extends StatefulWidget {
  const CombinedStateExample({super.key});

  @override
  State<CombinedStateExample> createState() => _CombinedStateExampleState();
}

class _CombinedStateExampleState extends State<CombinedStateExample> {
  /// 用户列表状态（Query）
  final usersState = ValueNotifier<DKStateQuery<List<User>>>(DkStateQueryIdle());

  /// 更新用户事件（Event）
  final updateUserEvent = StreamController<DKStateEvent<User>>();

  late final StreamSubscription<DKStateEvent<User>> _updateSubscription;

  void _loadUsers() {
    usersState.query(query: () => MockApiService.fetchUsers());
  }

  void _updateUser(User user) {
    updateUserEvent.triggerEvent(() => MockApiService.updateUser(user));
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();

    _updateSubscription = updateUserEvent.listenEvent(
      onLoading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新中...')),
        );
      },
      onSuccess: (user) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} 更新成功')),
        );
        // 更新成功后重新加载列表
        _loadUsers();
      },
      onError: (message, error, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $message')),
        );
      },
    );
  }

  @override
  void dispose() {
    _updateSubscription.cancel();
    updateUserEvent.close();
    usersState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('组合使用示例'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: usersState.display(
        successBuilder: (users) => ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.name),
              subtitle: Text(user.email),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _updateUser(
                  User(id: user.id, name: '${user.name}(已更新)', email: user.email),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==============================================================================
// 直接使用 State 类型（不使用扩展方法）
// ==============================================================================

/// 手动管理状态示例
///
/// 如果不想使用扩展方法，可以直接使用状态类
void manualStateExample() {
  // 手动创建状态
  DKStateQuery<String> state = DkStateQueryIdle();

  // 手动切换状态
  state = DkStateQueryLoading();
  state = DkStateQuerySuccess('数据');
  state = DkStateQueryError('错误信息');
  state = DkStateQueryEmpty();

  // 状态判断
  if (state.isLoading) {
    print('加载中');
  } else if (state.isSuccess) {
    print('成功: ${state.data}');
  } else if (state.isError) {
    print('错误: ${state.errorMessage}');
  } else if (state.isEmpty) {
    print('空数据');
  } else if (state.isIdle) {
    print('空闲');
  }

  // Event 状态同理
  DKStateEvent<String> event = DKStateEventIdle();
  event = DKStateEventLoading('run-id-123');
  event = DKStateEventSuccess('run-id-123', '数据');
  event = DKStateEventError('run-id-123', '错误信息');
  debugPrint('Event: $event'); // 使用变量避免警告
}

// ==============================================================================
// 使用说明
// ==============================================================================

/// # DKState 使用总结
///
/// ## DKStateQuery - 查询状态管理
/// 适用场景：GET 请求、页面数据加载、需要持久化显示的数据
///
/// 基本用法：
/// ```dart
/// final state = ValueNotifier<DKStateQuery<T>>(DkStateQueryIdle());
/// state.query(query: () => fetchData());
/// state.display(successBuilder: (data) => Widget());
/// ```
///
/// ## DKStateEvent - 事件状态管理
/// 适用场景：POST/PUT/DELETE 请求、表单提交、一次性事件
///
/// 基本用法：
/// ```dart
/// final event = StreamController<DKStateEvent<T>>();
/// event.triggerEvent(() => submitData());
/// event.listenEvent(
///   onLoading: () {},
///   onSuccess: (data) {},
///   onError: (msg, err, stack) {},
/// );
/// ```
///
/// ## 选择建议
/// - 需要在 UI 上持续显示状态变化 → 使用 DKStateQuery
/// - 只需要处理一次性结果（如显示 Toast）→ 使用 DKStateEvent
/// - 两者可以在同一页面组合使用
