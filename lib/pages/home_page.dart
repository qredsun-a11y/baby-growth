import 'package:flutter/material.dart';

import '../data/recommendation.dart';
import '../db/database_helper.dart';
import '../models/baby.dart';
import '../models/meal.dart';
import '../models/nutrient.dart';
import '../services/app_state.dart';
import '../services/nutrition_service.dart';
import '../theme.dart';
import '../widgets/food_source_sheet.dart';
import '../widgets/nutrient_progress.dart';
import 'baby_manager_page.dart';
import 'baby_profile_page.dart';
import 'data_manager_page.dart';
import 'growth_page.dart';
import 'meal_detail_page.dart';
import 'meal_record_page.dart';
import 'nutrition_advice_page.dart';
import 'report_page.dart';
import 'reminder_page.dart';

/// 首页：宝宝切换 + 今日营养概览 + 今日餐次列表 + 功能入口。
/// 监听 AppState，切换宝宝后自动刷新。
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
  final List<Meal> _todayMeals = []; // 今日全部餐次，用于"今日食物来源"面板
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onBabyChanged);
    _refresh();
  }

  void _onBabyChanged() => _refresh();

  @override
  void dispose() {
    AppState.instance.removeListener(_onBabyChanged);
    super.dispose();
  }

  /// 重新读取全部数据（跟随当前宝宝）
  Future<void> _refresh() async {
    setState(() => _loading = true);
    final baby = AppState.instance.baby;
    final now = DateTime.now();
    final intake = await NutritionService.instance.intakeForDate(now);
    final target = baby == null ? const Nutrient() : Recommendation.forBaby(baby);
    final meals = await DatabaseHelper.instance.getMealsByDate(
      now,
      AppState.instance.activeBabyId ?? 1,
    );

    if (!mounted) return;
    setState(() {
      _baby = baby;
      _intake = intake;
      _target = target;
      _meals.clear();
      _todayMeals
        ..clear()
        ..addAll(meals); // 保存今日餐次，供"今日食物来源"面板统计
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
            icon: const Icon(Icons.backup),
            tooltip: '数据导入导出',
            onPressed: () => _go(() => const DataManagerPage()).then((_) => _refresh()),
          ),
          IconButton(
            icon: const Icon(Icons.switch_account),
            tooltip: '宝宝管理',
            onPressed: () => _go(() => const BabyManagerPage()).then((_) => _refresh()),
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
          subtitle: const Text('点这里添加第一个宝宝'),
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
        subtitle: Text('身高 ${baby.heightCm.toStringAsFixed(0)}cm　体重 ${baby.weightKg.toStringAsFixed(1)}kg · 点击切换'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _go(() => const BabyManagerPage()).then((_) => _refresh()),
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
      onLabelTap: () => _showFoodSources(key),
    );
  }

  /// 点击营养名称：弹出该营养素的食物来源面板
  void _showFoodSources(String key) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FoodSourceSheet(
        nutrientKey: key,
        todayMeals: _todayMeals,
      ),
    );
  }

  /// 快捷入口四宫格
  Widget _buildQuickEntries() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.6,
      children: [
        _entryCard(Icons.lightbulb_outline, AppTheme.accent, '营养建议', () => _go(() => const NutritionAdvicePage())),
        _entryCard(Icons.bar_chart, AppTheme.primary, '营养报告', () => _go(() => const ReportPage())),
        _entryCard(Icons.trending_up, AppTheme.good, '成长曲线', () => _go(() => const GrowthPage())),
        _entryCard(Icons.alarm, AppTheme.low, '用餐提醒', () => _go(() => const ReminderPage())),
      ],
    );
  }

  Widget _entryCard(IconData icon, Color color, String label, Future Function() onTap) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
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
