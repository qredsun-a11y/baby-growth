import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../services/nutrition_service.dart';
import '../theme.dart';

/// 营养建议页：展示当天的定制建议清单。
class NutritionAdvicePage extends StatefulWidget {
  const NutritionAdvicePage({super.key});

  @override
  State<NutritionAdvicePage> createState() => _NutritionAdvicePageState();
}

class _NutritionAdvicePageState extends State<NutritionAdvicePage> {
  List<Advice> _advice = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final baby = await DatabaseHelper.instance.getBaby();
    if (baby == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '请先到「宝宝档案」填写信息';
      });
      return;
    }
    final advice = await NutritionService.instance.adviceForDate(DateTime.now(), baby);
    if (!mounted) return;
    setState(() {
      _advice = advice;
      _loading = false;
    });
  }

  IconData _iconFor(AdviceLevel level) {
    switch (level) {
      case AdviceLevel.good:
        return Icons.check_circle;
      case AdviceLevel.low:
        return Icons.warning_amber_rounded;
      case AdviceLevel.high:
        return Icons.error_outline;
      case AdviceLevel.warn:
        return Icons.info_outline;
    }
  }

  Color _colorFor(AdviceLevel level) {
    switch (level) {
      case AdviceLevel.good:
        return AppTheme.good;
      case AdviceLevel.low:
        return AppTheme.low;
      case AdviceLevel.high:
        return AppTheme.high;
      case AdviceLevel.warn:
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今日营养建议')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => _loading = true);
          _load();
        },
        child: const Icon(Icons.refresh),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: AppTheme.accent.withOpacity(0.12),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '根据今日记录 + 宝宝档案定制生成。达成率低于 60% 提示补充，高于 130% 提示减量。',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._advice.map((a) => Card(
                          child: ListTile(
                            leading: Icon(_iconFor(a.level), color: _colorFor(a.level)),
                            title: Text(a.text),
                          ),
                        )),
                    const SizedBox(height: 16),
                    const Text(
                      '⚠️ 建议基于内置营养库和公开膳食指南的近似值，仅供参考，不替代医生或营养师的专业诊断。如有特殊健康状况请咨询专业人士。',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
    );
  }
}
