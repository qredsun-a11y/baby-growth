import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/baby.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'baby_profile_page.dart';

/// 宝宝管理页：列出所有宝宝，可切换当前宝宝、新增、编辑、删除。
class BabyManagerPage extends StatefulWidget {
  const BabyManagerPage({super.key});

  @override
  State<BabyManagerPage> createState() => _BabyManagerPageState();
}

class _BabyManagerPageState extends State<BabyManagerPage> {
  List<Baby> _babies = [];
  int? _activeId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final babies = await DatabaseHelper.instance.getBabies();
    if (!mounted) return;
    setState(() {
      _babies = babies;
      _activeId = AppState.instance.activeBabyId;
      _loading = false;
    });
  }

  Future<void> _switch(int id) async {
    await AppState.instance.switchTo(id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已切换宝宝')),
    );
  }

  Future<void> _add() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BabyProfilePage()),
    );
    await _load();
  }

  Future<void> _edit(Baby baby) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BabyProfilePage(babyId: baby.id)),
    );
    await _load();
  }

  Future<void> _delete(Baby baby) async {
    if (_babies.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少保留一个宝宝')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除「${baby.name}」？'),
        content: const Text('该宝宝的所有餐次记录、成长记录、常用组合都会一并删除，无法恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await DatabaseHelper.instance.deleteBaby(baby.id!);
    // 若删的是当前宝宝，AppState.refresh 会自动回退到第一个
    if (_activeId == baby.id) {
      await AppState.instance.refresh();
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('宝宝管理')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('添加宝宝'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _babies.isEmpty
              ? const Center(child: Text('还没有宝宝，点右下角添加'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: _babies.length,
                  itemBuilder: (ctx, i) {
                    final baby = _babies[i];
                    final active = baby.id == _activeId;
                    return Card(
                      color: active ? AppTheme.primary.withOpacity(0.08) : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: active ? AppTheme.primary : Colors.grey.shade300,
                          child: Text(
                            baby.name.isEmpty ? '宝' : baby.name.substring(0, 1),
                            style: TextStyle(color: active ? Colors.white : Colors.grey.shade700),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(baby.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (active) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('当前', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text('${baby.ageLabel} · ${baby.heightCm.toStringAsFixed(0)}cm · ${baby.weightKg.toStringAsFixed(1)}kg'),
                        trailing: active
                            ? const Icon(Icons.check_circle, color: AppTheme.primary)
                            : TextButton(
                                onPressed: () => _switch(baby.id!),
                                child: const Text('切换'),
                              ),
                        onTap: () => _edit(baby),
                        onLongPress: () => _delete(baby),
                      ),
                    );
                  },
                ),
    );
  }
}
