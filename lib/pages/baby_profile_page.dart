import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/baby.dart';

/// 宝宝档案页：新建/编辑宝宝信息，含定制字段（过敏/个头/缺铁）。
class BabyProfilePage extends StatefulWidget {
  const BabyProfilePage({super.key});

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
  String _sizeStatus = 'normal';
  bool _ironRisk = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final baby = await DatabaseHelper.instance.getBaby();
    if (baby != null) {
      _nameCtrl.text = baby.name;
      _birthDate = baby.birthDate;
      _heightCtrl.text = baby.heightCm.toStringAsFixed(0);
      _weightCtrl.text = baby.weightKg.toStringAsFixed(1);
      _allergyCtrl.text = baby.allergies;
      _sizeStatus = baby.sizeStatus;
      _ironRisk = baby.ironRisk;
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
      id: 1,
      name: _nameCtrl.text.trim(),
      birthDate: _birthDate!,
      heightCm: double.tryParse(_heightCtrl.text) ?? 0,
      weightKg: double.tryParse(_weightCtrl.text) ?? 0,
      allergies: _allergyCtrl.text.trim(),
      sizeStatus: _sizeStatus,
      ironRisk: _ironRisk,
    );
    await DatabaseHelper.instance.saveBaby(baby);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存，营养目标已更新')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('宝宝档案')),
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
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('偏小'),
                          selected: _sizeStatus == 'small',
                          onSelected: (_) => setState(() => _sizeStatus = 'small'),
                        ),
                        ChoiceChip(
                          label: const Text('正常'),
                          selected: _sizeStatus == 'normal',
                          onSelected: (_) => setState(() => _sizeStatus = 'normal'),
                        ),
                        ChoiceChip(
                          label: const Text('偏大'),
                          selected: _sizeStatus == 'large',
                          onSelected: (_) => setState(() => _sizeStatus = 'large'),
                        ),
                      ],
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
