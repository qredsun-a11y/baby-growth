import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../data/food_database.dart';
import '../db/database_helper.dart';
import '../models/favorite_combo.dart';
import '../models/food.dart';
import '../models/meal.dart';
import '../services/app_state.dart';
import '../theme.dart';

/// 进食记录页：选餐次 → 选食物+份量 → 拍照 → 备注 → 保存。
/// 同时支持"新建"和"编辑"（传入 mealId 即为编辑）。
class MealRecordPage extends StatefulWidget {
  final int? mealId; // 传入则编辑已有记录

  const MealRecordPage({super.key, this.mealId});

  @override
  State<MealRecordPage> createState() => _MealRecordPageState();
}

class _MealRecordPageState extends State<MealRecordPage> {
  String _mealType = Meal.typeLunch;
  DateTime _date = DateTime.now();
  final Map<String, double> _selected = {}; // foodId -> 克数
  final Map<String, TextEditingController> _gramCtrl = {}; // foodId -> 自定义克重输入框
  final _noteCtrl = TextEditingController();
  final _vitaminACtrl = TextEditingController(); // 额外补充的维生素A (μg)
  final _vitaminCCtrl = TextEditingController(); // 额外补充的维生素C (mg)
  File? _photo;
  String? _savedPhotoPath;
  bool _loading = false;
  List<FavoriteCombo> _combos = [];

  @override
  void initState() {
    super.initState();
    if (widget.mealId != null) _loadMeal();
    _loadCombos();
  }

  Future<void> _loadCombos() async {
    final babyId = AppState.instance.activeBabyId ?? 1;
    final combos = await DatabaseHelper.instance.getCombos(babyId);
    if (!mounted) return;
    setState(() => _combos = combos);
  }

  Future<void> _loadMeal() async {
    setState(() => _loading = true);
    final meal = await DatabaseHelper.instance.getMeal(widget.mealId!);
    if (meal != null) {
      _mealType = meal.mealType;
      _date = meal.date;
      _noteCtrl.text = meal.note;
      _vitaminACtrl.text = meal.vitaminASupplement > 0
          ? _formatGrams(meal.vitaminASupplement) : '';
      _vitaminCCtrl.text = meal.vitaminCSupplement > 0
          ? _formatGrams(meal.vitaminCSupplement) : '';
      _savedPhotoPath = meal.photoPath;
      if (_savedPhotoPath != null) _photo = File(_savedPhotoPath!);
      try {
        final raw = _parseFoods(meal.foodsJson);
        for (final mf in raw) {
          _selected[mf.foodId] = mf.grams;
          _gramCtrl[mf.foodId] = TextEditingController(text: _formatGrams(mf.grams));
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  List<MealFood> _parseFoods(String json) {
    // 用 model 里的 fromMap 需要解码，这里简单手动走一遍
    final list = Meal.decodeFoods(json);
    return list;
  }

  /// 拍照 / 从相册选
  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1200);
    if (xFile == null) return;
    // 复制到 App 私有目录，避免临时路径失效
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'meal_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await File(xFile.path).copy('${dir.path}/$fileName');
    setState(() {
      _photo = saved;
      _savedPhotoPath = saved.path;
    });
  }

  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 套用常用组合：清空当前选择，按组合的食物+克数填入
  void _applyCombo(FavoriteCombo combo) {
    setState(() {
      for (final c in _gramCtrl.values) {
        c.dispose();
      }
      _selected.clear();
      _gramCtrl.clear();
      for (final mf in combo.foods) {
        if (FoodDatabase.byId(mf.foodId) == null) continue;
        _selected[mf.foodId] = mf.grams;
        _gramCtrl[mf.foodId] = TextEditingController(text: _formatGrams(mf.grams));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已套用「${combo.name}」')),
    );
  }

  /// 把当前选中的食物保存为常用组合
  Future<void> _saveAsCombo() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先选好食物，再保存为组合')),
      );
      return;
    }
    final nameCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('保存为常用组合'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '组合名称',
            hintText: '如：早餐常吃 / 补铁套餐',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('请填组合名称')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final combo = FavoriteCombo.fromMapData(
      babyId: AppState.instance.activeBabyId ?? 1,
      name: nameCtrl.text.trim(),
      items: Map<String, double>.from(_selected),
    );
    await DatabaseHelper.instance.insertCombo(combo);
    await _loadCombos();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已保存组合「${combo.name}」')),
    );
  }

  /// 删除常用组合
  Future<void> _deleteCombo(FavoriteCombo combo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除组合「${combo.name}」？'),
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
      await DatabaseHelper.instance.deleteCombo(combo.id!);
      await _loadCombos();
    }
  }

  /// 点食物：未选则加入默认份量，已选则移除
  void _toggleFood(Food food) {
    setState(() {
      if (_selected.containsKey(food.id)) {
        _selected.remove(food.id);
        _gramCtrl.remove(food.id)?.dispose();
      } else {
        _selected[food.id] = 100; // 默认 100g
        _gramCtrl[food.id] = TextEditingController(text: '100');
      }
    });
  }

  /// 克数显示：整数不带小数，非整数保留一位
  String _formatGrams(double g) =>
      g == g.roundToDouble() ? g.toStringAsFixed(0) : g.toStringAsFixed(1);

  /// 自定义克重输入：只接受正数，失焦时把合法值写回 _selected
  void _onCustomGramsChanged(Food food, String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null && parsed > 0) _selected[food.id] = parsed;
  }

  /// 补充剂输入 → 数值（非法/空按 0）
  double _supplementValue(TextEditingController c) {
    final v = double.tryParse(c.text.trim());
    return (v != null && v >= 0) ? v : 0;
  }

  bool get _hasContent =>
      _selected.isNotEmpty ||
      _supplementValue(_vitaminACtrl) > 0 ||
      _supplementValue(_vitaminCCtrl) > 0;

  Future<void> _save() async {
    if (!_hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少选一个食物或填一项补充剂')),
      );
      return;
    }
    final foods = _selected.entries
        .map((e) => MealFood(foodId: e.key, grams: e.value).toMap())
        .toList();
    final meal = Meal(
      id: widget.mealId,
      babyId: AppState.instance.activeBabyId ?? 1,
      mealType: _mealType,
      date: _date,
      foodsJson: Meal.encodeFoods(foods),
      photoPath: _savedPhotoPath,
      note: _noteCtrl.text.trim(),
      vitaminASupplement: _supplementValue(_vitaminACtrl),
      vitaminCSupplement: _supplementValue(_vitaminCCtrl),
    );
    if (widget.mealId == null) {
      await DatabaseHelper.instance.insertMeal(meal);
    } else {
      await DatabaseHelper.instance.updateMeal(meal);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mealId == null ? '记录这一餐' : '编辑这一餐'),
        actions: [
          if (_hasContent)
            TextButton(onPressed: _save, child: const Text('保存', style: TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
      floatingActionButton: !_hasContent
          ? null
          : FloatingActionButton.extended(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('保存这一餐'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('餐次'),
                  Wrap(
                    spacing: 8,
                    children: Meal.typeLabels.entries.map((e) {
                      return ChoiceChip(
                        label: Text(e.value),
                        selected: _mealType == e.key,
                        onSelected: (_) => setState(() => _mealType = e.key),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('常用组合'),
                  _buildCombosSection(),
                  const SizedBox(height: 20),
                  _sectionTitle('吃了什么（点击选择）'),
                  ...FoodDatabase.categories.map((cat) => _buildCategory(cat)),
                  const SizedBox(height: 20),
                  _buildSupplementsSection(),
                  const SizedBox(height: 20),
                  _sectionTitle('拍张照片'),
                  GestureDetector(
                    onTap: _showPhotoSheet,
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _photo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(_photo!, fit: BoxFit.cover),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                        onPressed: () => setState(() {
                                          _photo = null;
                                          _savedPhotoPath = null;
                                        }),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('点击拍照或从相册选（留档用）', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('备注'),
                  TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      hintText: '如：今天胃口不好 / 吃了大半碗',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  /// 常用组合：横向 chips 一键套用 + "存为组合"按钮
  Widget _buildCombosSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ..._combos.map((combo) => InputChip(
              avatar: const Icon(Icons.fastfood, size: 16),
              label: Text(combo.name),
              onPressed: () => _applyCombo(combo),
              onDeleted: () => _deleteCombo(combo),
              deleteIconColor: Colors.grey,
            )),
        ActionChip(
          avatar: const Icon(Icons.add, size: 16),
          label: const Text('存为组合'),
          backgroundColor: AppTheme.primary.withOpacity(0.12),
          onPressed: _saveAsCombo,
        ),
        if (_combos.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('选好食物后可存为常用组合', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
      ],
    );
  }

  /// 额外补充剂（鱼肝油/维C片等）：单独计入该餐，不影响食物克重
  Widget _buildSupplementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('额外补充剂（可选）'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '吃了鱼肝油、维生素片等补充剂时填这里，会算进当天的营养摄入。没有就留空。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.healing, size: 18, color: AppTheme.accent),
                    const SizedBox(width: 6),
                    const Text('维生素A', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _vitaminACtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: '0',
                          suffixText: 'μg',
                          suffixStyle: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.healing, size: 18, color: AppTheme.accent),
                    const SizedBox(width: 6),
                    const Text('维生素C', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _vitaminCCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: '0',
                          suffixText: 'mg',
                          suffixStyle: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 一个分类下的食物网格
  Widget _buildCategory(String cat) {
    final foods = FoodDatabase.foods.where((f) => f.category == cat).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(cat, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: foods.map((food) {
            final selected = _selected.containsKey(food.id);
            return FilterChip(
              label: Text(food.name),
              selected: selected,
              selectedColor: AppTheme.primary.withOpacity(0.25),
              onSelected: (_) => _toggleFood(food),
            );
          }).toList(),
        ),
        if (_selected.entries.any((e) => foods.any((f) => f.id == e.key)))
          const SizedBox(height: 6),
        ...foods.where((f) => _selected.containsKey(f.id)).map((food) => _gramRow(food)),
      ],
    );
  }

  /// 已选食物的份量调节行：快捷档位 + 自定义克重输入
  Widget _gramRow(Food food) {
    final grams = _selected[food.id] ?? 100;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Text('${food.name}：', style: const TextStyle(fontSize: 13)),
          _gramButton('少', 50, grams, food),
          _gramButton('中', 100, grams, food),
          _gramButton('多', 150, grams, food),
          const SizedBox(width: 8),
          SizedBox(
            width: 76,
            height: 32,
            child: TextField(
              controller: _gramCtrl[food.id],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                hintText: '克重',
                suffixText: 'g',
                suffixStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => _onCustomGramsChanged(food, v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gramButton(String label, double value, double current, Food food) {
    final active = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: SizedBox(
        height: 28,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            backgroundColor: active ? AppTheme.primary : null,
            foregroundColor: active ? Colors.white : null,
            side: BorderSide(color: active ? AppTheme.primary : Colors.grey.shade400),
          ),
          onPressed: () => setState(() {
            _selected[food.id] = value;
            // 同步输入框，避免快捷档位与自定义值显示不一致
            _gramCtrl[food.id]?.text = _formatGrams(value);
          }),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _gramCtrl.values) {
      c.dispose();
    }
    _noteCtrl.dispose();
    _vitaminACtrl.dispose();
    _vitaminCCtrl.dispose();
    super.dispose();
  }
}
