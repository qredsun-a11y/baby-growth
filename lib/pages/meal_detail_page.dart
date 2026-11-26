import 'dart:io';

import 'package:flutter/material.dart';

import '../data/food_database.dart';
import '../db/database_helper.dart';
import '../models/meal.dart';
import '../theme.dart';
import 'meal_record_page.dart';

/// 餐次详情页：看这一餐吃了什么、照片、备注；可编辑/删除。
class MealDetailPage extends StatefulWidget {
  final int mealId;

  const MealDetailPage({super.key, required this.mealId});

  @override
  State<MealDetailPage> createState() => _MealDetailPageState();
}

class _MealDetailPageState extends State<MealDetailPage> {
  Meal? _meal;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meal = await DatabaseHelper.instance.getMeal(widget.mealId);
    if (!mounted) return;
    setState(() {
      _meal = meal;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final meal = _meal;
    if (meal == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MealRecordPage(mealId: meal.id)),
    );
    _load();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这一餐？'),
        content: const Text('删除后无法恢复'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteMeal(widget.mealId);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final meal = _meal;
    if (meal == null) {
      return const Scaffold(body: Center(child: Text('记录不存在')));
    }
    final foods = Meal.decodeFoods(meal.foodsJson);

    return Scaffold(
      appBar: AppBar(
        title: Text('${meal.typeLabel} · ${meal.date.month}/${meal.date.day}'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
          IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (meal.photoPath != null && File(meal.photoPath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(meal.photoPath!),
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                ),
              ),
            if (meal.photoPath != null) const SizedBox(height: 16),
            const Text('吃了什么', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: foods.map((mf) {
                  final food = FoodDatabase.byId(mf.foodId);
                  return ListTile(
                    title: Text(food?.name ?? mf.foodId),
                    subtitle: Text('约 ${mf.grams.toStringAsFixed(0)}g'),
                    trailing: Text(
                      '${(food!.kcal * mf.grams / 100).toStringAsFixed(0)} kcal',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('备注', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(meal.note.isEmpty ? '（无）' : meal.note),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '用餐时间 ${meal.date.hour.toString().padLeft(2, '0')}:${meal.date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
