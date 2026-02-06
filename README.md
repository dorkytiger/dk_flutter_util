# 如何在其他项目中使用 DK Util

本文档详细说明如何在你的其他 Flutter 项目中使用 dk_util 工具库。

## 📋 目录

1. [快速开始](#快速开始)
2. [两种种引用方式](#两种引用方式)
3. [完整示例](#完整示例)
4. [常见问题](#常见问题)

---

## 🚀 快速开始

### 1. 在目标项目中添加依赖

假设你有一个新项目 `my_app`，项目结构如下：

```
workspace/
├── dk_util/          # 工具库项目
└── my_app/           # 你的目标项目
    └── pubspec.yaml
```

编辑 `my_app/pubspec.yaml`：

```yaml
name: my_app
description: My Flutter App

dependencies:
  flutter:
    sdk: flutter
  
  # 添加 dk_util 依赖（使用相对路径）
  dk_util:
    path: ../dk_util
```

### 2. 运行 pub get

```bash
cd my_app
flutter pub get
```

### 3. 开始使用

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:dk_util/dk_util.dart';  // 导入所有功能

void main() {
  // 配置日志
  DKLog.setLevel(DKLogLevel.debug);
  DKLog.i('应用启动', tag: 'App');
  
  runApp(MyApp());
}
```

---

## 📦 两种引用方式

### 方式 1: 本地路径引用


```yaml
dependencies:
  dk_util:
    path: ../dk_util  # 相对路径
    # 或
    path: /home/dorkytiger/IdeaProjects/dk_util  # 绝对路径
```


---

### 方式 2: Git 仓库引用

```yaml
dependencies:
  dk_util:
    git:
      url: https://github.com/yourusername/dk_util.git
      ref: main  # 分支名、tag 或 commit hash
      # 可选：指定子目录
      # path: packages/dk_util
```

**版本管理示例**：

```yaml
# 使用特定分支
dk_util:
  git:
    url: https://github.com/yourusername/dk_util.git
    ref: develop

# 使用特定 tag
dk_util:
  git:
    url: https://github.com/yourusername/dk_util.git
    ref: v1.0.0

# 使用特定 commit
dk_util:
  git:
    url: https://github.com/yourusername/dk_util.git
    ref: abc1234
```

## 💡 完整示例

### 示例 1: 使用日志工具

创建新项目 `my_app`：

```bash
flutter create my_app
cd my_app
```

编辑 `pubspec.yaml`：

```yaml
dependencies:
  flutter:
    sdk: flutter
  dk_util:
    path: ../dk_util  # 假设 dk_util 和 my_app 在同一目录下
```

编辑 `lib/main.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dk_util/dk_util_log.dart';  // 只导入日志模块

void main() {
  // 配置日志：生产环境禁用
  if (kReleaseMode) {
    DKLog.setEnabled(false);
  } else {
    DKLog.setLevel(DKLogLevel.debug);
  }
  
  DKLog.i('应用启动', tag: 'App');
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DKLog.d('构建 MyApp Widget', tag: 'UI');
    
    return MaterialApp(
      title: 'DK Util Demo',
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  void handleButtonClick() {
    DKLog.i('按钮被点击', tag: 'Event');
    
    try {
      // 模拟可能出错的操作
      throw Exception('演示异常处理');
    } catch (e, stackTrace) {
      DKLog.e('操作失败', tag: 'Error', error: e, stackTrace: stackTrace);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('DK Util Demo')),
      body: Center(
        child: ElevatedButton(
          onPressed: handleButtonClick,
          child: Text('点击测试日志'),
        ),
      ),
    );
  }
}
```

运行：

```bash
flutter run
```

---

### 示例 2: 使用状态管理

编辑 `lib/main.dart`：

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dk_util/dk_util.dart';  // 导入所有功能

void main() {
  DKLog.setLevel(DKLogLevel.debug);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DK Util State Demo',
      home: UserListPage(),
    );
  }
}

class UserListPage extends StatefulWidget {
  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  // 查询状态：用于显示用户列表
  final usersState = ValueNotifier<DkStateQuery<List<String>>>(
    DkStateQueryIdle(),
  );
  
  // 事件状态：用于添加用户
  final addUserEvent = StreamController<DKStateEvent<void>>();
  late final StreamSubscription _subscription;
  
  @override
  void initState() {
    super.initState();
    
    // 监听添加用户事件
    _subscription = addUserEvent.listenEvent(
      onLoading: () {
        DKLog.d('正在添加用户...', tag: 'User');
      },
      onSuccess: (_, message) {
        DKLog.i('用户添加成功', tag: 'User');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('添加成功')),
          );
          // 重新加载列表
          loadUsers();
        }
      },
      onError: (message, error, stackTrace) {
        DKLog.e('添加用户失败: $message', tag: 'User');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('添加失败: $message')),
          );
        }
      },
    );
    
    // 初始加载
    loadUsers();
  }
  
  // 加载用户列表
  void loadUsers() async {
    usersState.value = DkStateQueryLoading();
    
    try {
      DKLog.d('开始加载用户列表', tag: 'User');
      await Future.delayed(Duration(seconds: 1));
      
      final users = ['Alice', 'Bob', 'Charlie', 'David'];
      usersState.value = DkStateQuerySuccess(users);
      
      DKLog.i('加载了 ${users.length} 个用户', tag: 'User');
    } catch (e) {
      usersState.value = DkStateQueryError(e.toString());
      DKLog.e('加载失败', tag: 'User', error: e);
    }
  }
  
  // 添加用户
  void addUser() {
    addUserEvent.triggerEvent(() async {
      await Future.delayed(Duration(seconds: 1));
      // 模拟操作
    });
  }
  
  @override
  void dispose() {
    _subscription.cancel();
    addUserEvent.close();
    usersState.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('用户列表'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: addUser,
          ),
        ],
      ),
      body: usersState.displayDkStateQuery(
        successBuilder: (users) {
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(users[index]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadUsers,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
```

现在你已经知道如何在其他项目中使用 dk_util 了！

如有任何问题，欢迎查看主 [README.md](README.md) 或提交 Issue。
