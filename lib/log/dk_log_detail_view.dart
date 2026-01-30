import 'dart:io';

import 'package:dk_util/state/dk_state_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/dk_state_query_flutter.dart';

/// 日志级别枚举
enum LogLevel {
  all('全部', null),
  debug('DEBUG', '🐛'),
  info('INFO', 'ℹ️'),
  warning('WARN', '⚠️'),
  error('ERROR', '❌'),
  fatal('FATAL', '💀');

  const LogLevel(this.label, this.icon);
  final String label;
  final String? icon;
}

class DKLogDetailView extends StatefulWidget {
  final File file;

  const DKLogDetailView({super.key, required this.file});

  @override
  State<DKLogDetailView> createState() => _DKLogDetailViewState();
}

class _DKLogDetailViewState extends State<DKLogDetailView> {
  final _getFileContentState = ValueNotifier<DKStateQuery<List<String>>>(
    DkStateQueryIdle(),
  );

  // 搜索控制器
  final TextEditingController _searchController = TextEditingController();

  // 当前选择的日志级别
  LogLevel _selectedLevel = LogLevel.all;

  // 搜索文本
  String _searchText = '';

  // 滚动控制器
  final ScrollController _scrollController = ScrollController();

  Future<void> _getFileContent() async {
    await _getFileContentState.query(
      query: () async {
        final content = await widget.file.readAsLines();
        return content;
      },
      isEmpty: (data) => data.isEmpty,
    );
  }

  @override
  void initState() {
    super.initState();
    _getFileContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _getFileContentState.dispose();
    super.dispose();
  }

  // 过滤日志行
  List<String> _filterLines(List<String> lines) {
    List<String> filtered = lines;

    // 按日志级别过滤
    if (_selectedLevel != LogLevel.all) {
      filtered = filtered.where((line) {
        // 检查是否包含日志级别标识
        final icon = _selectedLevel.icon;
        if (icon != null && line.contains(icon)) {
          return true;
        }
        // 或者检查是否包含日志级别文本
        if (line.contains('[${_selectedLevel.label}]')) {
          return true;
        }
        return false;
      }).toList();
    }

    // 按搜索文本过滤
    if (_searchText.isNotEmpty) {
      filtered = filtered.where((line) {
        return line.toLowerCase().contains(_searchText.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  // 获取日志行的颜色
  Color? _getLineColor(String line) {
    if (line.contains('❌') || line.contains('[ERROR]')) {
      return Colors.red.shade700;
    } else if (line.contains('⚠️') || line.contains('[WARN]')) {
      return Colors.orange.shade700;
    } else if (line.contains('ℹ️') || line.contains('[INFO]')) {
      return Colors.blue.shade700;
    } else if (line.contains('🐛') || line.contains('[DEBUG]')) {
      return Colors.grey.shade600;
    } else if (line.contains('💀') || line.contains('[FATAL]')) {
      return Colors.purple.shade700;
    }
    return null;
  }

  // 高亮搜索文本
  TextSpan _buildHighlightedText(String text) {
    if (_searchText.isEmpty) {
      return TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: _getLineColor(text),
        ),
      );
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerSearch = _searchText.toLowerCase();

    int start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerSearch, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: _getLineColor(text),
            ),
          ));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: _getLineColor(text),
          ),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + _searchText.length),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ));

      start = index + _searchText.length;
    }

    return TextSpan(children: spans);
  }

  // 复制内容到剪贴板
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.file.path.split('/').last;
    final fileSize = widget.file.lengthSync();
    final fileSizeKB = (fileSize / 1024).toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fileName, style: const TextStyle(fontSize: 16)),
            Text(
              '大小: ${fileSizeKB}KB',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // 复制全部按钮
          IconButton(
            icon: const Icon(Icons.copy_all),
            onPressed: () {
              final state = _getFileContentState.value;
              if (state is DkStateQuerySuccess<List<String>>) {
                _copyToClipboard(state.data.join('\n'));
              }
            },
            tooltip: '复制全部',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索日志内容...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
          ),

          // 日志级别筛选器
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: LogLevel.values.map((level) {
                final isSelected = _selectedLevel == level;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (level.icon != null) ...[
                          Text(level.icon!),
                          const SizedBox(width: 4),
                        ],
                        Text(level.label),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedLevel = level;
                      });
                    },
                    selectedColor: Colors.blue.shade100,
                    backgroundColor: Colors.grey.shade200,
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // 日志内容
          Expanded(
            child: _getFileContentState.display(
              successBuilder: (data) {
                final filteredLines = _filterLines(data);

                if (filteredLines.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          '没有匹配的日志',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '原始日志行数: ${data.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // 统计信息
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.blue.shade50,
                      child: Row(
                        children: [
                          Text(
                            '显示 ${filteredLines.length} / ${data.length} 行',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                            icon: const Icon(Icons.arrow_upward, size: 16),
                            label: const Text('回到顶部', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),

                    // 日志列表
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: filteredLines.length,
                        itemBuilder: (context, index) {
                          final line = filteredLines[index];

                          return InkWell(
                            onLongPress: () {
                              _copyToClipboard(line);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: index % 2 == 0
                                    ? Colors.grey.shade50
                                    : Colors.white,
                                border: Border(
                                  left: BorderSide(
                                    color: _getLineColor(line) ?? Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 行号
                                  Container(
                                    width: 50,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),

                                  // 日志内容
                                  Expanded(
                                    child: RichText(
                                      text: _buildHighlightedText(line),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
                    Text(
                      '加载失败',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _getFileContent,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              ),
              emptyBuilder: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      '日志文件为空',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
