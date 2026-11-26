import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/meal.dart';
import '../services/notification_service.dart';

/// 提醒设置页：早/午/晚三餐的开关 + 时间，保存到本地并注册定时通知。
class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  // 每餐：开关 + 小时 + 分钟
  final Map<String, bool> _enabled = {};
  final Map<String, int> _hour = {};
  final Map<String, int> _minute = {};
  bool _loading = true;

  // 通知 id 固定分配，避免重复注册
  static const _ids = {
    Meal.typeBreakfast: 101,
    Meal.typeLunch: 102,
    Meal.typeDinner: 103,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseHelper.instance.getReminders();
    for (final row in rows) {
      final type = row['mealType'] as String;
      _enabled[type] = (row['enabled'] as int) == 1;
      _hour[type] = row['hour'] as int;
      _minute[type] = row['minute'] as int;
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _pickTime(String type) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour[type] ?? 8, minute: _minute[type] ?? 0),
    );
    if (picked != null) {
      setState(() {
        _hour[type] = picked.hour;
        _minute[type] = picked.minute;
      });
    }
  }

  Future<void> _save() async {
    for (final entry in Meal.typeLabels.entries) {
      final type = entry.key;
      final on = _enabled[type] ?? false;
      final h = _hour[type] ?? 8;
      final m = _minute[type] ?? 0;

      await DatabaseHelper.instance.saveReminder(type, on, h, m);

      final id = _ids[type]!;
      if (on) {
        await NotificationService.instance.scheduleDaily(
          id: id,
          title: '该给宝宝记${entry.value}啦 🍚',
          body: '打开 App 记录这一餐吃了什么',
          hour: h,
          minute: m,
        );
      } else {
        await NotificationService.instance.cancel(id);
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('提醒已保存')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用餐提醒')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: const Text('保存提醒'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('到点提醒你记录宝宝这一餐，全部在本机运行，不联网。', style: TextStyle(color: Colors.grey)),
                ),
                ...Meal.typeLabels.entries.map((e) => _buildReminderRow(e.key, e.value)),
                const SizedBox(height: 24),
                const Text(
                  '提示：首次使用需允许通知权限。若提醒不响，请检查手机「设置 → 通知」里本 App 的权限，以及是否开启了省电限制。',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
    );
  }

  Widget _buildReminderRow(String type, String label) {
    final on = _enabled[type] ?? false;
    final h = _hour[type] ?? 8;
    final m = _minute[type] ?? 0;
    final time = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: Text(label),
            subtitle: Text('每天 $time 提醒'),
            value: on,
            onChanged: (v) => setState(() => _enabled[type] = v),
          ),
          if (on)
            ListTile(
              dense: true,
              leading: const Icon(Icons.access_time, size: 18),
              title: const Text('提醒时间'),
              trailing: Text(time, style: const TextStyle(fontSize: 16)),
              onTap: () => _pickTime(type),
            ),
        ],
      ),
    );
  }
}
