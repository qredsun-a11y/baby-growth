import 'package:flutter/material.dart';

import '../data/recommendation.dart';
import '../db/database_helper.dart';
import '../models/baby.dart';
import '../models/nutrient.dart';
import '../services/nutrition_service.dart';
import '../theme.dart';
import '../widgets/nutrient_progress.dart';
import 'baby_profile_page.dart';
import 'meal_detail_page.dart';
import 'meal_record_page.dart';
import 'nutrition_advice_page.dart';
import 'reminder_page.dart';

/// 首页：今日营养概览 + 今日餐次列表 + 功能入口。
/// 用 StatefulWidget，进页面/返回时刷新数据（setState 手动刷新）。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Baby? _baby;
  Nutrient _intake = const Nutrient();
  Nutrient _target = const Nutrient();
  final List<_TodayMeal> _meals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// 重新读取全部数据
  Future<void> _refresh() async {
    setState(() => _loading = true);
    final baby = await DatabaseHelper.instance.getBaby();
    final now = DateTime.now();
    final intake = await NutritionService.instance.intakeForDate(now);
    final target = baby == null
        ? const Nutrient()
        : Recommendation.forBaby(baby);
    final meals = await DatabaseHelper.instance.getMealsByDate(now);

    if (!mounted) return;
    setState(() {
      _baby = baby;
      _intake = intake;
      _target = target;
      _meals.clear();
      for (final m in meals) {
        _meals.add(_TodayMeal(
          id: m.id!,
          typeLabel: m.typeLabel,
          time: '${m.date.hour.toString().padLeft(2, '0')}:${m.date.minute.toString().padLeft(2, '0')}',
          hasPhoto: m.photoPath != null,
        ));
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('宝宝营养助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '宝宝档案',
            onPressed: () => _go(() => const BabyProfilePage()).then((_) => _refresh()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _go(() => const MealRecordPage()).then((_) => _refresh()),
        icon: const Icon(Icons.add),
        label: const Text('记录这一餐'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                children: [
                  _buildBabyCard(),
                  const SizedBox(height: 12),
                  _buildOverviewCard(),
                  const SizedBox(height: 12),
                  _buildQuickEntries(),
                  const SizedBox(height: 12),
                  _buildMealList(),
                ],
              ),
            ),
    );
  }

  /// 顶部宝宝信息卡
  Widget _buildBabyCard() {
    final baby = _baby;
    if (baby == null) {
      return Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.child_care)),
          title: const Text('还没有宝宝档案'),
          subtitle: const Text('点右上角设置，填一下宝宝信息'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _go(() => const BabyProfilePage()).then((_) => _refresh()),
        ),
      );
    }
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primary,
          child: Text('👶', style: TextStyle(fontSize: 22)),
        ),
        title: Text('${baby.name} · ${baby.ageLabel}'),
        subtitle: Text('身高 ${baby.heightCm.toStringAsFixed(0)}cm　体重 ${baby.weightKg.toStringAsFixed(1)}kg'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _go(() => const BabyProfilePage()).then((_) => _refresh()),
      ),
    );
  }

  /// 今日营养概览卡
  Widget _buildOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('今日营养', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            _progress('kcal'),
            const SizedBox(height: 12),
            _progress('protein'),
            const SizedBox(height: 12),
            _progress('iron'),
            const SizedBox(height: 12),
            _progress('calcium'),
            const SizedBox(height: 12),
            _progress('vitaminA'),
            const SizedBox(height: 12),
            _progress('vitaminC'),
          ],
        ),
      ),
    );
  }

  Widget _progress(String key) {
    return NutrientProgress(
      label: Nutrient.labels[key]!,
      value: _intake.valueOf(key),
      target: _target.valueOf(key),
      unit: Nutrient.units[key]!,
    );
  }

  /// 快捷入口：营养建议 / 提醒设置
  Widget _buildQuickEntries() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.lightbulb_outline, color: AppTheme.accent),
              title: const Text('营养建议'),
              onTap: () => _go(() => const NutritionAdvicePage()),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.alarm, color: AppTheme.primary),
              title: const Text('用餐提醒'),
              onTap: () => _go(() => const ReminderPage()),
            ),
          ),
        ),
      ],
    );
  }

  /// 今日餐次列表
  Widget _buildMealList() {
    if (_meals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('今天还没有记录，点下面按钮记第一餐吧')),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('今日餐次', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ..._meals.map((m) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accent.withOpacity(0.15),
                  child: Icon(
                    m.hasPhoto ? Icons.photo_camera : Icons.restaurant,
                    color: AppTheme.accent,
                  ),
                ),
                title: Text(m.typeLabel),
                subtitle: Text(m.time),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _go(() => MealDetailPage(mealId: m.id)).then((_) => _refresh()),
              ),
            )),
      ],
    );
  }

  /// 统一页面跳转
  Future<T?> _go<T>(Widget Function() builder) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (_) => builder()),
    );
  }
}

/// 首页列表用的精简餐次数据
class _TodayMeal {
  final int id;
  final String typeLabel;
  final String time;
  final bool hasPhoto;

  _TodayMeal({
    required this.id,
    required this.typeLabel,
    required this.time,
    required this.hasPhoto,
  });
}
