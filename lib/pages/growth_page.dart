import 'package:flutter/material.dart';

import '../data/growth_standards.dart';
import '../db/database_helper.dart';
import '../models/baby.dart';
import '../models/growth_record.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/line_chart.dart';

/// 成长曲线页：身高/体重随月龄变化，叠加 WHO 0-3 岁 P3/P97 标准曲线，
/// 并按最新测量自动判定个头偏差（偏小/正常/偏大）写回档案。
class GrowthPage extends StatefulWidget {
  const GrowthPage({super.key});

  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage> {
  Baby? _baby;
  List<GrowthRecord> _records = [];
  int _metric = 0; // 0=身高 1=体重
  bool _loading = true;
  String _autoSizeStatus = 'normal';
  String _sizeNote = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final babyId = AppState.instance.activeBabyId ?? 1;
    final baby = await DatabaseHelper.instance.getBaby(babyId);
    final records = await DatabaseHelper.instance.getGrowthRecords(babyId);
    if (!mounted) return;
    setState(() {
      _baby = baby;
      _records = records;
      _loading = false;
    });
    await _autoClassify();
  }

  /// 用最新一次测量（没有则用档案身高体重）按 WHO 标准自动判型，写回档案。
  /// 若家长在档案里手动指定了 sizeStatusManual，则不覆盖。
  Future<void> _autoClassify() async {
    final baby = _baby;
    if (baby == null) return;
    final month = baby.ageInMonths;
    double h = baby.heightCm;
    double w = baby.weightKg;
    if (_records.isNotEmpty) {
      final last = _records.last;
      h = last.heightCm;
      w = last.weightKg;
    }
    final status = GrowthStandards.classifySize(baby.gender, month, h, w);
    final hr = GrowthStandards.heightRange(baby.gender, month);
    final wr = GrowthStandards.weightRange(baby.gender, month);
    final hPos = GrowthStandards.classify(h, hr.p3, hr.p97);
    final wPos = GrowthStandards.classify(w, wr.p3, wr.p97);
    final posText = (v) => v < 0 ? '低于P3' : (v > 0 ? '高于P97' : 'P3~P97');
    if (!mounted) return;
    setState(() {
      _autoSizeStatus = status;
      _sizeNote = '身高${posText(hPos)} · 体重${posText(wPos)}（${month}月龄·${baby.genderLabel}）';
    });
    if (!baby.sizeStatusManual && baby.sizeStatus != status) {
      final updated = Baby(
        id: baby.id,
        name: baby.name,
        gender: baby.gender,
        birthDate: baby.birthDate,
        heightCm: h,
        weightKg: w,
        allergies: baby.allergies,
        sizeStatus: status,
        sizeStatusManual: false,
        ironRisk: baby.ironRisk,
      );
      await DatabaseHelper.instance.saveBaby(updated);
      await AppState.instance.refresh();
    }
  }

  Future<void> _addRecord() async {
    final babyId = AppState.instance.activeBabyId ?? 1;
    final baby = _baby;
    if (baby == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写宝宝档案')),
      );
      return;
    }
    final now = DateTime.now();
    final dateCtrl = TextEditingController(
      text: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    );
    final heightCtrl = TextEditingController(
      text: _records.isEmpty ? baby.heightCm.toStringAsFixed(0) : '',
    );
    final weightCtrl = TextEditingController(
      text: _records.isEmpty ? baby.weightKg.toStringAsFixed(1) : '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('记录一次测量'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateCtrl,
                readOnly: true,
                decoration: const InputDecoration(labelText: '测量日期', prefixIcon: Icon(Icons.calendar_today)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: now,
                    firstDate: baby.birthDate,
                    lastDate: DateTime.now(),
                    locale: const Locale('zh', 'CN'),
                  );
                  if (picked != null) {
                    dateCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: heightCtrl,
                decoration: const InputDecoration(labelText: '身高 (cm)', prefixIcon: Icon(Icons.height)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightCtrl,
                decoration: const InputDecoration(labelText: '体重 (kg)', prefixIcon: Icon(Icons.fitness_center_outlined)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final h = double.tryParse(heightCtrl.text);
              final w = double.tryParse(weightCtrl.text);
              if (h == null || h <= 0 || w == null || w <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('请填写有效的身高和体重')),
                );
                return;
              }
              _pendingRecord = GrowthRecord(
                babyId: babyId,
                date: DateTime.tryParse(dateCtrl.text) ?? now,
                heightCm: h,
                weightKg: w,
              );
              Navigator.pop(ctx, true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved == true && _pendingRecord != null) {
      await DatabaseHelper.instance.insertGrowth(_pendingRecord!);
      _pendingRecord = null;
      await _load();
    }
  }

  GrowthRecord? _pendingRecord;

  Future<void> _delete(GrowthRecord r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这条记录？'),
        content: Text('${r.date.month}/${r.date.day} 的测量记录，删除后无法恢复'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteGrowth(r.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('成长曲线'),
        actions: [
          IconButton(icon: const Icon(Icons.add), tooltip: '记录测量', onPressed: _addRecord),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        icon: const Icon(Icons.add),
        label: const Text('记录测量'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSizeCard(),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('身高/年龄'),
                              selected: _metric == 0,
                              onSelected: (_) => setState(() => _metric = 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('体重/年龄'),
                              selected: _metric == 1,
                              onSelected: (_) => setState(() => _metric = 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildChartCard(),
                  const SizedBox(height: 16),
                  _buildRecordList(),
                  const SizedBox(height: 16),
                  const Text(
                    '参考曲线为 WHO 0-3 岁儿童生长标准（P3/P97），约 94% 健康儿童在此区间内。'
                    '仅用于观察趋势，不是医学诊断；早产儿需按矫正月龄并咨询医生。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSizeCard() {
    final baby = _baby;
    if (baby == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('请先填写宝宝档案'),
        ),
      );
    }
    final color = _autoSizeStatus == 'small'
        ? AppTheme.low
        : (_autoSizeStatus == 'large' ? AppTheme.high : AppTheme.good);
    final label = GrowthStandards.sizeLabels[_autoSizeStatus] ?? '正常';
    return Card(
      color: color.withOpacity(0.10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: color),
                const SizedBox(width: 8),
                Text('个头偏差（自动判定）：$label',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 6),
            Text(_sizeNote, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            if (baby.sizeStatusManual)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('档案里已手动指定，自动判定不会覆盖。',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final baby = _baby;
    if (baby == null) return const SizedBox.shrink();
    final isHeight = _metric == 0;
    final metric = isHeight ? '身高' : '体重';
    final unit = isHeight ? 'cm' : 'kg';

    final p3 = isHeight
        ? (baby.gender == 'female' ? GrowthStandards.girlHeightP3 : GrowthStandards.boyHeightP3)
        : (baby.gender == 'female' ? GrowthStandards.girlWeightP3 : GrowthStandards.boyWeightP3);
    final p97 = isHeight
        ? (baby.gender == 'female' ? GrowthStandards.girlHeightP97 : GrowthStandards.boyHeightP97)
        : (baby.gender == 'female' ? GrowthStandards.girlWeightP97 : GrowthStandards.boyWeightP97);

    // P3/P97 标准曲线（0-36 月龄）
    final p3Points = <ChartPoint>[];
    final p97Points = <ChartPoint>[];
    for (int m = 0; m <= 36; m++) {
      p3Points.add(ChartPoint(m.toDouble(), p3[m]));
      p97Points.add(ChartPoint(m.toDouble(), p97[m]));
    }
    // 宝宝实测点：按测量时的月龄定位到 X 轴
    final realPoints = _records
        .map((r) => ChartPoint(
              baby.ageInMonthsAt(r.date).toDouble(),
              isHeight ? r.heightCm : r.weightKg,
            ))
        .toList();

    final series = <LineSeries>[
      LineSeries(
        points: p97Points,
        color: Colors.orange.shade300,
        label: 'P97',
        dashed: true,
        strokeWidth: 1.5,
      ),
      LineSeries(
        points: p3Points,
        color: Colors.orange.shade300,
        label: 'P3',
        dashed: true,
        strokeWidth: 1.5,
      ),
      if (realPoints.isNotEmpty)
        LineSeries(
          points: realPoints,
          color: isHeight ? AppTheme.primary : AppTheme.accent,
          label: '实测',
          strokeWidth: 2.8,
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$metric / 年龄百分位曲线', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${baby.genderLabel}童 · 0-3 岁 · WHO 标准',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            LineChart(
              series: series,
              yUnit: unit,
              height: 240,
              xMin: 0,
              xMax: 36,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.show_chart, size: 14, color: Colors.orange),
                Text(' 虚线 P3/P97（正常区间）', style: TextStyle(fontSize: 11, color: Colors.grey)),
                SizedBox(width: 12),
                Icon(Icons.circle, size: 10, color: AppTheme.primary),
                Text(' 宝宝实测', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordList() {
    if (_records.isEmpty) return const SizedBox.shrink();
    final reversed = _records.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('测量记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...reversed.map((r) {
          final baby = _baby!;
          final m = baby.ageInMonthsAt(r.date);
          final hr = GrowthStandards.heightRange(baby.gender, m);
          final wr = GrowthStandards.weightRange(baby.gender, m);
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.15),
                child: const Icon(Icons.straighten, color: AppTheme.primary),
              ),
              title: Text('${r.date.year}/${r.date.month}/${r.date.day} · $m 月龄'),
              subtitle: Text(
                '身高 ${r.heightCm.toStringAsFixed(1)}cm (P3 ${hr.p3.toStringAsFixed(0)}~P97 ${hr.p97.toStringAsFixed(0)})　\n'
                '体重 ${r.weightKg.toStringAsFixed(1)}kg (P3 ${wr.p3.toStringAsFixed(1)}~P97 ${wr.p97.toStringAsFixed(1)})',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: () => _delete(r),
              ),
            ),
          );
        }),
      ],
    );
  }
}
