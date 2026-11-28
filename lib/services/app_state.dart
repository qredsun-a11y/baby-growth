import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../models/baby.dart';

/// 全局 App 状态：管理"当前选中的宝宝"。
/// 当前宝宝 id 存本地 app_settings，切换后通知所有监听者刷新。
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  static const _keyActiveBaby = 'activeBabyId';

  int? _activeBabyId;
  Baby? _baby;
  bool _initialized = false;

  int? get activeBabyId => _activeBabyId;
  Baby? get baby => _baby;

  Future<void> init() async {
    if (_initialized) return;
    final saved = await DatabaseHelper.instance.getSetting(_keyActiveBaby);
    int? id = saved == null ? null : int.tryParse(saved);
    final babies = await DatabaseHelper.instance.getBabies();
    // 存档 id 失效（宝宝被删）时回退到第一个宝宝
    if (id == null || !babies.any((b) => b.id == id)) {
      id = babies.isEmpty ? null : babies.first.id;
    }
    _activeBabyId = id;
    _baby = id == null ? null : await DatabaseHelper.instance.getBaby(id);
    _initialized = true;
  }

  /// 切换当前宝宝并持久化
  Future<void> switchTo(int babyId) async {
    final baby = await DatabaseHelper.instance.getBaby(babyId);
    if (baby == null) return;
    _activeBabyId = babyId;
    _baby = baby;
    await DatabaseHelper.instance.setSetting(_keyActiveBaby, babyId.toString());
    notifyListeners();
  }

  /// 宝宝档案改动后刷新缓存
  Future<void> refresh() async {
    final id = _activeBabyId;
    if (id == null) {
      _baby = null;
    } else {
      _baby = await DatabaseHelper.instance.getBaby(id);
      // 宝宝可能被删了
      if (_baby == null) {
        final babies = await DatabaseHelper.instance.getBabies();
        _activeBabyId = babies.isEmpty ? null : babies.first.id;
        _baby = _activeBabyId == null
            ? null
            : await DatabaseHelper.instance.getBaby(_activeBabyId!);
        await _persistActive();
      }
    }
    notifyListeners();
  }

  Future<void> _persistActive() async {
    if (_activeBabyId == null) {
      await DatabaseHelper.instance.setSetting(_keyActiveBaby, '');
    } else {
      await DatabaseHelper.instance.setSetting(_keyActiveBaby, _activeBabyId.toString());
    }
  }

  /// 新增宝宝后设为当前
  Future<void> addBabyAndSelect(int babyId) async {
    await switchTo(babyId);
  }
}
