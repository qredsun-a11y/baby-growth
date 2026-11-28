import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../db/database_helper.dart';
import '../models/baby.dart';
import '../models/favorite_combo.dart';
import '../models/growth_record.dart';
import '../models/meal.dart';
import 'app_state.dart';

/// 数据备份服务：把所有本地数据导出成 JSON 文件，或从 JSON 文件导入恢复。
/// 全程在本地完成，不联网。
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const formatVersion = 1;

  /// 导出：读取所有表 → 组装成 JSON 字符串
  Future<String> exportJson() async {
    final db = await DatabaseHelper.instance.database;
    final babyRows = await db.query('baby', orderBy: 'id ASC');
    final mealRows = await db.query('meals', orderBy: 'id ASC');
    final growthRows = await db.query('growth_records', orderBy: 'id ASC');
    final comboRows = await db.query('favorite_combos', orderBy: 'id ASC');
    final reminderRows = await db.query('reminders', orderBy: 'mealType ASC');
    final settingRows = await db.query('app_settings');

    final data = {
      'app': 'baby_nutrition',
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'babies': babyRows,
      'meals': mealRows,
      'growthRecords': growthRows,
      'favoriteCombos': comboRows,
      'reminders': reminderRows,
      'settings': settingRows,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 导出到文件，返回文件路径
  Future<String> exportToFile() async {
    final json = await exportJson();
    final dir = await getApplicationDocumentsDirectory();
    final name = 'baby_nutrition_backup_${_stamp()}.json';
    final file = File('${dir.path}/$name');
    await file.writeAsString(json, encoding: utf8);
    return file.path;
  }

  String _stamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  /// 导入：解析 JSON 校验 → 清空现有表 → 写入。返回导入了多少条宝宝记录。
  /// 注意：会覆盖当前所有数据，调用方需先让用户确认。
  Future<int> importFromJson(String content) async {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('文件格式不对：顶层不是对象');
    }
    if (decoded['app'] != 'baby_nutrition') {
      throw const FormatException('这不是本 App 的备份文件');
    }
    final version = decoded['formatVersion'];
    if (version is! int || version > formatVersion) {
      throw const FormatException('备份文件版本过高，无法导入');
    }

    final babies = _asList(decoded['babies']);
    if (babies.isEmpty) {
      throw const FormatException('备份文件里没有宝宝档案');
    }
    // 结构预校验：每行都能转成模型，避免导入一半失败
    for (final row in babies) {
      Baby.fromMap(Map<String, Object?>.from(row as Map));
    }
    for (final row in _asList(decoded['meals'])) {
      Meal.fromMap(Map<String, Object?>.from(row as Map));
    }
    for (final row in _asList(decoded['growthRecords'])) {
      GrowthRecord.fromMap(Map<String, Object?>.from(row as Map));
    }
    for (final row in _asList(decoded['favoriteCombos'])) {
      FavoriteCombo.fromMap(Map<String, Object?>.from(row as Map));
    }

    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    // 清空所有业务表（保留表结构）
    for (final table in [
      'baby', 'meals', 'growth_records', 'favorite_combos', 'reminders', 'app_settings'
    ]) {
      batch.delete(table);
    }
    for (final row in babies) {
      batch.insert('baby', Map<String, Object?>.from(row as Map));
    }
    for (final row in _asList(decoded['meals'])) {
      batch.insert('meals', Map<String, Object?>.from(row as Map));
    }
    for (final row in _asList(decoded['growthRecords'])) {
      batch.insert('growth_records', Map<String, Object?>.from(row as Map));
    }
    for (final row in _asList(decoded['favoriteCombos'])) {
      batch.insert('favorite_combos', Map<String, Object?>.from(row as Map));
    }
    for (final row in _asList(decoded['reminders'])) {
      batch.insert('reminders', Map<String, Object?>.from(row as Map));
    }
    for (final row in _asList(decoded['settings'])) {
      batch.insert('app_settings', Map<String, Object?>.from(row as Map));
    }
    await batch.commit(noResult: true);

    // 导入后把当前宝宝重置到第一个有效 id（存档 id 可能指向已不存在的宝宝）
    final firstId = Baby.fromMap(Map<String, Object?>.from(babies.first as Map)).id;
    if (firstId != null) {
      await DatabaseHelper.instance.setSetting('activeBabyId', firstId.toString());
    }
    await AppState.instance.refresh();
    return babies.length;
  }

  List<dynamic> _asList(dynamic v) => (v is List) ? v : const [];
}
