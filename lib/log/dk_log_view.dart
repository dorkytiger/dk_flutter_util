import 'dart:io';

import 'package:dk_util/dk_util.dart';
import 'package:dk_util/log/dk_log_detail_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class DKLogView extends StatefulWidget {
  const DKLogView({super.key});

  @override
  State<DKLogView> createState() => _DKLogViewState();
}

class _DKLogViewState extends State<DKLogView> {
  final _getFileState = ValueNotifier<DKStateQuery<List<File>>>(
    DkStateQueryIdle(),
  );

  // 选中的文件集合
  final Set<String> _selectedFiles = {};

  // 是否处于选择模式
  bool _isSelectionMode = false;

  Future<void> _getFile() async {
    await _getFileState.query(
      query: () => DKLog.getLogFiles(),
      isEmpty: (data) => data.isEmpty,
    );
  }

  // 切换选择模式
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedFiles.clear();
      }
    });
  }

  // 切换文件选中状态
  void _toggleFileSelection(String filePath) {
    setState(() {
      if (_selectedFiles.contains(filePath)) {
        _selectedFiles.remove(filePath);
      } else {
        _selectedFiles.add(filePath);
      }
    });
  }

  // 全选/取消全选
  void _toggleSelectAll(List<File> files) {
    setState(() {
      if (_selectedFiles.length == files.length) {
        _selectedFiles.clear();
      } else {
        _selectedFiles.clear();
        for (final file in files) {
          _selectedFiles.add(file.path);
        }
      }
    });
  }

  // 导出选中的文件
  Future<void> _exportSelectedFiles() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要导出的文件')),
      );
      return;
    }

    try {
      // 让用户选择导出目录
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        // 用户取消了选择
        return;
      }

      // 显示进度对话框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在导出文件...'),
            ],
          ),
        ),
      );

      // 导出文件
      int successCount = 0;
      final state = _getFileState.value;
      if (state is DkStateQuerySuccess<List<File>>) {
        final allFiles = state.data;

        for (final file in allFiles) {
          if (_selectedFiles.contains(file.path)) {
            try {
              final fileName = file.path.split('/').last;
              final targetPath = '$selectedDirectory/$fileName';
              await file.copy(targetPath);
              successCount++;
              DKLog.i('文件已导出: $targetPath', tag: 'LogExport');
            } catch (e) {
              DKLog.e('导出文件失败: ${file.path}', tag: 'LogExport', error: e);
            }
          }
        }
      }

      // 关闭进度对话框
      if (!mounted) return;
      Navigator.of(context).pop();

      // 显示结果
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功导出 $successCount 个文件到:\n$selectedDirectory'),
          duration: const Duration(seconds: 3),
        ),
      );

      // 退出选择模式
      _toggleSelectionMode();

    } catch (e) {
      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      DKLog.e('导出失败', tag: 'LogExport', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  // 删除选中的文件
  Future<void> _deleteSelectedFiles() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要删除的文件')),
      );
      return;
    }

    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedFiles.length} 个文件吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      int deletedCount = 0;
      final state = _getFileState.value;
      if (state is DkStateQuerySuccess<List<File>>) {
        final allFiles = state.data;

        for (final file in allFiles) {
          if (_selectedFiles.contains(file.path)) {
            try {
              await file.delete();
              deletedCount++;
              DKLog.i('文件已删除: ${file.path}', tag: 'LogDelete');
            } catch (e) {
              DKLog.e('删除文件失败: ${file.path}', tag: 'LogDelete', error: e);
            }
          }
        }
      }

      // 刷新列表
      await _getFile();

      // 退出选择模式
      _toggleSelectionMode();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功删除 $deletedCount 个文件')),
      );

    } catch (e) {
      DKLog.e('删除失败', tag: 'LogDelete', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getFile();
  }

  @override
  void dispose() {
    _getFileState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: _isSelectionMode
              ? Text('已选择 ${_selectedFiles.length} 个文件')
              : const Text('日志文件查看'),
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSelectionMode,
                )
              : null,
          actions: _isSelectionMode
              ? [
                  // 全选/取消全选
                  IconButton(
                    icon: Icon(
                      _selectedFiles.length == (_getFileState.value is DkStateQuerySuccess<List<File>>
                          ? (_getFileState.value as DkStateQuerySuccess<List<File>>).data.length
                          : 0)
                          ? Icons.deselect
                          : Icons.select_all,
                    ),
                    onPressed: () {
                      final state = _getFileState.value;
                      if (state is DkStateQuerySuccess<List<File>>) {
                        _toggleSelectAll(state.data);
                      }
                    },
                    tooltip: '全选/取消全选',
                  ),
                  // 导出按钮
                  IconButton(
                    icon: const Icon(Icons.file_upload),
                    onPressed: _exportSelectedFiles,
                    tooltip: '导出选中文件',
                  ),
                  // 删除按钮
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteSelectedFiles,
                    tooltip: '删除选中文件',
                  ),
                ]
              : [
                  // 测试日志按钮
                  IconButton(
                    onPressed: () {
                      DKLog.d("这是一条调试日志", tag: 'Test');
                      DKLog.i("这是一条信息日志", tag: 'Test');
                      DKLog.w("这是一条警告日志", tag: 'Test');
                      DKLog.e("这是一条错误日志", tag: 'Test');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已写入测试日志'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report),
                    tooltip: '写入测试日志',
                  ),
                  // 选择模式按钮
                  IconButton(
                    icon: const Icon(Icons.checklist),
                    onPressed: _toggleSelectionMode,
                    tooltip: '选择模式',
                  ),
                  // 刷新按钮
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _getFile,
                    tooltip: '刷新',
                  ),
                ],
        ),
        body: _getFileState.display(
          successBuilder: (data) {
            if (data.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      '暂无日志文件',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        DKLog.d("测试调试日志", tag: 'Test');
                        DKLog.i("测试信息日志", tag: 'Test');
                        DKLog.w("测试警告日志", tag: 'Test');
                        DKLog.e("测试错误日志", tag: 'Test');
                        _getFile();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('生成测试日志'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final file = data[index];
                final fileName = file.path.split('/').last;
                final fileSize = file.lengthSync();
                final fileSizeKB = (fileSize / 1024).toStringAsFixed(2);
                final modifiedTime = file.lastModifiedSync();
                final isSelected = _selectedFiles.contains(file.path);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: isSelected ? 4 : 1,
                  color: isSelected ? Colors.blue.shade50 : null,
                  child: ListTile(
                    leading: _isSelectionMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (value) => _toggleFileSelection(file.path),
                          )
                        : const Icon(Icons.description, color: Colors.blue),
                    title: Text(
                      fileName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.storage, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('大小: ${fileSizeKB}KB'),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '修改: ${modifiedTime.toString().substring(0, 19)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: _isSelectionMode
                        ? null
                        : const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleFileSelection(file.path);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => DKLogDetailView(file: file),
                          ),
                        );
                      }
                    },
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        _toggleSelectionMode();
                        _toggleFileSelection(file.path);
                      }
                    },
                  ),
                );
              },
            );
          },
          loadingBuilder: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在加载日志文件...'),
              ],
            ),
          ),
          errorBuilder: (message) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                const Text(
                  '加载失败',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _getFile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
