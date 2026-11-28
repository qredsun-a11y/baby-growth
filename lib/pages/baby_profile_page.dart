import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/baby.dart';
import '../services/app_state.dart';

/// 宝宝档案页：新建/编辑宝宝信息，含定制字段（过敏/个头/缺铁）。
/// V2：babyId == null 表示新增宝宝；否则编辑指定宝宝。
class BabyProfilePage extends StatefulWidget {
  final int? babyId;

  const BabyProfilePage({super.key, this.babyId});

  @override
  State<BabyProfilePage> createState() => _BabyProfilePageState();
}

class _BabyProfilePageState extends State<BabyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _allergyCtrl = TextEditingController();

  DateTime? _birthDate; // 初始为空，由用户自行选择出生日期
  String _gender = Baby.genderMale; // 性别：决定用哪套 WHO 百分位标准
  String _sizeStatus = 'normal';
  bool _sizeStatusManual = false; // 手动指定个头偏差（否则由成长曲线自动判定）
  bool _ironRisk = false;
  bool _loading = true;
  bool get _isNew => widget.babyId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // 新增宝宝：身高体重留空更合理（还没出生/还没量），但保留 0 让用户填
    if (!_isNew) {
      final baby = await DatabaseHelper.instance.getBaby(widget.babyId!);
      if (baby != null) {
        _nameCtrl.text = baby.name;
        _gender = baby.gender;
        _birthDate = baby.birthDate;
        _heightCtrl.text = baby.heightCm.toStringAsFixed(0);
        _weightCtrl.text = baby.weightKg.toStringAsFixed(1);
        _allergyCtrl.text = baby.allergies;
        _sizeStatus = baby.sizeStatus;
        _sizeStatusManual = baby.sizeStatusManual;
        _ironRisk = baby.ironRisk;
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 540)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 6)),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择出生日期')),
      );
      return;
    }
    final baby = Baby(
      id: widget.babyId,
      name: _nameCtrl.text.trim(),
      gender: _gender,
      birthDate: _birthDate!,
      heightCm: double.tryParse(_heightCtrl.text) ?? 0,
      weightKg: double.tryParse(_weightCtrl.text) ?? 0,
      allergies: _allergyCtrl.text.trim(),
      sizeStatus: _sizeStatus,
      sizeStatusManual: _sizeStatusManual,
      ironRisk: _ironRisk,
    );
    final savedId = await DatabaseHelper.instance.saveBaby(baby);
    if (_isNew) {
      await AppState.instance.addBabyAndSelect(savedId);
    } else {
      await AppState.instance.refresh();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isNew ? '宝宝已添加' : '已保存，营养目标已更新')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? '添加宝宝' : '编辑宝宝档案')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: '宝宝昵称'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? '请填昵称' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('性别（用于选生长标准曲线）'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('男'),
                          selected: _gender == Baby.genderMale,
                          onSelected: (_) => setState(() => _gender = Baby.genderMale),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('女'),
                          selected: _gender == Baby.genderFemale,
                          onSelected: (_) => setState(() => _gender = Baby.genderFemale),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('出生日期'),
                      subtitle: _birthDate == null
                          ? const Text('请选择')
                          : Text('${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _heightCtrl,
                            decoration: const InputDecoration(labelText: '身高 (cm)'),
                            keyboardType: TextInputType.number,
                            validator: (v) => (v == null || v.isEmpty) ? '请填身高' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _weightCtrl,
                            decoration: const InputDecoration(labelText: '体重 (kg)'),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => (v == null || v.isEmpty) ? '请填体重' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('定制选项', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _allergyCtrl,
                      decoration: const InputDecoration(
                        labelText: '过敏食物',
                        hintText: '如：花生,牛奶（逗号分隔，没有就留空）',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('个头偏差'),
                    const SizedBox(height: 4),
                    Text(
                      _sizeStatusManual
                          ? '当前为手动指定；关闭下方开关后由成长曲线按 WHO 百分位自动判定。'
                          : '当前由成长曲线按 WHO 百分位自动判定（低于P3偏小 / 高于P97偏大）。',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('偏小'),
                          selected: _sizeStatusManual && _sizeStatus == 'small',
                          onSelected: (_) => setState(() {
                            _sizeStatus = 'small';
                            _sizeStatusManual = true;
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('正常'),
                          selected: _sizeStatusManual && _sizeStatus == 'normal',
                          onSelected: (_) => setState(() {
                            _sizeStatus = 'normal';
                            _sizeStatusManual = true;
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('偏大'),
                          selected: _sizeStatusManual && _sizeStatus == 'large',
                          onSelected: (_) => setState(() {
                            _sizeStatus = 'large';
                            _sizeStatusManual = true;
                          }),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('手动指定个头偏差'),
                      subtitle: const Text('关闭则根据身高体重的百分位自动判定'),
                      value: _sizeStatusManual,
                      onChanged: (v) => setState(() => _sizeStatusManual = v),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('有缺铁风险'),
                      subtitle: const Text('勾选后铁推荐量会提高，并重点提醒补铁'),
                      value: _ironRisk,
                      onChanged: (v) => setState(() => _ironRisk = v),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _save,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('保存'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '营养建议仅供参考，不替代医生或营养师的专业诊断。',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _allergyCtrl.dispose();
    super.dispose();
  }
}
