import 'package:flutter/material.dart';

import '../data/recommendation.dart';
import '../models/baby.dart';
import '../models/nutrient.dart';
import '../services/app_state.dart';
import '../services/nutrition_service.dart';
import '../theme.dart';
import '../widgets/bar_chart.dart';

/// 营养报告页：按周（近7天）/月（近30天）汇总摄入均值 vs 推荐量。
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _range = 7; // 7 或 30 天
  bool _loading = true;
  final Baby? _baby = AppState.instance.baby;

  int _recordedDays = 0;
  Nutrient _dailyAvg = const Nutrient();
  Nutrient _target = const Nutrient();
  Map<String, Nutrient> _byDay = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: _range - 1));
    final end = today.add(const Duration(days: 1)); // 含今天

    final byDay = await NutritionService.instance.intakeByDay(start, end);
    final available = byDay.values.where((n) => _hasIntake(n)).length;

    Nutrient sum = const Nutrient();
    for (final n in byDay.values) {
      sum = sum + n;
    }
    // 均值按"有记录的天数"算，没记的天不拉低平均（同时单独显示记录天数）
    final days = available == 0 ? 1 : available;
    final avg = Nutrient(
      kcal: sum.kcal / days,
      protein: sum.protein / days,
      iron: sum.iron / days,
      calcium: sum.calcium / days,
      vitaminA: sum.vitaminA / days,
      vitaminC: sum.vitaminC / days,
    );
    final target = _baby == null ? const Nutrient() : Recommendation.forBaby(_baby!);

    if (!mounted) return;
    setState(() {
      _byDay = byDay;
      _recordedDays = available;
      _dailyAvg = avg;
      _target = target;
      _loading = false;
    });
  }

  bool _hasIntake(Nutrient n) =>
      n.kcal > 0 || n.protein > 0 || n.iron > 0 || n.calcium > 0;

  static const _keys = ['kcal', 'protein', 'iron', 'calcium', 'vitaminA', 'vitaminC'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('营养报告'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: '刷新', onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('近 7 天'),
                          selected: _range == 7,
                          onSelected: (_) {
                            if (_range != 7) setState(() => _range = 7);
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('近 30 天'),
                          selected: _range == 30,
                          onSelected: (_) {
                            if (_range != 30) setState(() => _range = 30);
                            _load();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_baby == null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('请先添加宝宝档案', style: TextStyle(color: Colors.grey.shade700)),
                      ),
                    )
                  else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _stat('有记录天数', '$_recordedDays / $_range 天'),
                            _stat('日均热量', '${_dailyAvg.kcal.toStringAsFixed(0)} kcal'),
                            _stat('目标热量', '${_target.kcal.toStringAsFixed(0)} kcal'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAvgCard(),
                    const SizedBox(height: 12),
                    _buildTrendCard(),
                    const SizedBox(height: 16),
                    const Text(
                      '报告基于内置营养库的近似值和已记录数据，仅供参考，不替代医生或营养师的专业诊断。',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  /// 日均摄入 vs 推荐：横向条形对比（复用自绘柱状图）
  Widget _buildAvgCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('日均摄入', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('各营养素单位不同，柱高仅表示达成率趋势（相对推荐量）', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            // 用"达成率 %"画图，统一量纲
            BarChart(
              height: 220,
              items: _keys.map((key) {
                final r = _dailyAvg.ratioOf(_target, key) * 100;
                return BarItem(
                  label: Nutrient.labels[key]!,
                  value: r > 200 ? 200 : r,
                  color: _ratioColor(r / 100),
                );
              }).toList(),
              referenceValue: 100,
            ),
            const SizedBox(height: 8),
            const Text('虚线 = 推荐量 100%；柱高为日均摄入占推荐量的百分比（封顶 200%）', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 12),
            ..._keys.map((key) => _ratioRow(key)),
          ],
        ),
      ),
    );
  }

  Widget _ratioRow(String key) {
    final value = _dailyAvg.valueOf(key);
    final goal = _target.valueOf(key);
    final r = goal > 0 ? value / goal : 0.0;
    final pct = (r * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${Nutrient.labels[key]}　${value.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} ${Nutrient.units[key]}'),
          Text(
            '$pct%',
            style: TextStyle(
              color: _ratioColor(r),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _ratioColor(double r) {
    if (r < 0.6) return AppTheme.low;
    if (r > 1.3) return AppTheme.high;
    return AppTheme.good;
  }

  /// 热量按天趋势折线（复用柱状图，每天一根柱）
  Widget _buildTrendCard() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final items = <BarItem>[];
    for (int i = _range - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final key = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final kcal = _byDay[key]?.kcal ?? 0;
      items.add(BarItem(
        label: '${day.month}/${day.day}',
        value: kcal,
        color: kcal > 0 ? AppTheme.primary : Colors.grey.shade300,
      ));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('每日热量趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            BarChart(
              height: 200,
              items: items,
              referenceValue: _target.kcal,
            ),
          ],
        ),
      ),
    );
  }
}
