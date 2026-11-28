import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/backup_service.dart';
import '../theme.dart';

/// 数据管理页：把全部本地数据导出为 JSON 文件，或从 JSON 备份恢复。
class DataManagerPage extends StatefulWidget {
  const DataManagerPage({super.key});

  @override
  State<DataManagerPage> createState() => _DataManagerPageState();
}

class _DataManagerPageState extends State<DataManagerPage> {
  bool _busy = false;
  String? _message;

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final path = await BackupService.instance.exportToFile();
      final file = XFile(path);
      await Share.shareXFiles(
        [file],
        subject: '宝宝营养助手数据备份',
        text: '这是宝宝营养助手的数据备份文件，请妥善保存。',
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = '已导出并打开分享，选择保存到手机或发送给他人。\n文件位置：$path';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = '导出失败：$e';
      });
    }
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: false,
      );
      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _message = '已取消选择文件';
        });
        return;
      }
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      // 先解析校验，确认能读再让用户确认覆盖
      final previewOk = await _validate(content);
      if (!previewOk) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _message = '文件格式不正确，或不是本 App 的备份';
        });
        return;
      }
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('确认导入？'),
          content: const Text(
            '导入会覆盖当前所有数据（宝宝档案、餐次、成长记录、常用组合、提醒设置），无法撤销。\n建议先导出一份当前数据备份。',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认导入', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm != true) {
        if (!mounted) return;
        setState(() => _busy = false);
        return;
      }
      final count = await BackupService.instance.importFromJson(content);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = '导入成功，共恢复 $count 个宝宝的数据。';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = '导入失败：$e';
      });
    }
  }

  /// 轻量校验：JSON 语法 + 关键字段；完整校验在 importFromJson 里再做一次
  Future<bool> _validate(String content) async {
    try {
      final decoded = jsonDecode(content);
      return decoded is Map<String, dynamic> && decoded['app'] == 'baby_nutrition';
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据导入导出')),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('导出数据', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text(
                            '把宝宝档案、所有餐次记录、成长记录、常用组合和提醒设置打包成一个 JSON 文件，'
                            '通过系统分享保存到手机或发给别人。全程在本机完成，不上传网络。',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _export,
                    icon: const Icon(Icons.ios_share),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('导出为 JSON 文件'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('导入数据', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text(
                            '从之前导出的 JSON 备份文件恢复数据。导入会覆盖当前所有数据，操作前请确认。',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _import,
                    icon: const Icon(Icons.file_upload),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('选择 JSON 文件导入'),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 20),
                    Card(
                      color: AppTheme.accent.withOpacity(0.10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_message!, style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    '提示：导出的文件包含宝宝健康相关数据，请妥善保管，避免泄露个人隐私。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}
