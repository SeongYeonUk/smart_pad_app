import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pad_app/models/user_model.dart';
import 'package:smart_pad_app/models/diet_log_model.dart';
import 'package:smart_pad_app/providers/auth_provider.dart';
import 'package:smart_pad_app/services/api_service.dart';

class DietInfoScreen extends StatefulWidget {
  const DietInfoScreen({super.key});

  @override
  State<DietInfoScreen> createState() => _DietInfoScreenState();
}

class _DietInfoScreenState extends State<DietInfoScreen> {
  List<DietLogModel> _dietLogs = [];
  bool _isLoading = true;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadDietLogs();
  }

  Future<void> _loadDietLogs() async {
    _user = Provider.of<AuthProvider>(context, listen: false).user;

    if (_user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final logs = await ApiService.getDietLogs(_user!.id);
      if (!mounted) return;
      setState(() {
        _dietLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('식단 기록을 불러오는 데 실패했습니다: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _showAddDietLogModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return AddDietLogForm(
          onAddDietLog: (created) {
            setState(() {
              _dietLogs = [created, ..._dietLogs];
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('식단 기록이 추가되었습니다.')),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('식생활 정보')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dietLogs.isEmpty
          ? const Center(child: Text('식단 기록이 없습니다.'))
          : ListView.builder(
        itemCount: _dietLogs.length,
        itemBuilder: (context, index) {
          final log = _dietLogs[index];
          final d = log.date;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: _getMealIcon(log.mealType, theme),
              title: Text('${d.year}.${d.month}.${d.day} (${log.mealType})'),
              subtitle: Text(
                '주요리: ${log.mainDish}'
                    '${log.subDish != null && log.subDish!.isNotEmpty ? ", 부요리: ${log.subDish}" : ""}',
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDietLogModal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getMealIcon(String mealType, ThemeData theme) {
    IconData iconData;
    switch (mealType) {
      case '아침':
        iconData = Icons.wb_sunny_outlined;
        break;
      case '점심':
        iconData = Icons.fastfood_outlined;
        break;
      case '저녁':
        iconData = Icons.nights_stay_outlined;
        break;
      default:
        iconData = Icons.restaurant;
    }
    return Icon(iconData, color: theme.primaryColor);
  }
}

// ===== 추가 폼 =====

class AddDietLogForm extends StatefulWidget {
  final void Function(DietLogModel created) onAddDietLog;

  const AddDietLogForm({super.key, required this.onAddDietLog});

  @override
  State<AddDietLogForm> createState() => _AddDietLogFormState();
}

class _AddDietLogFormState extends State<AddDietLogForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String? _selectedMealType;
  final _mainDishController = TextEditingController();
  final _subDishController = TextEditingController();
  bool _saving = false;

  Future<void> _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    final newDietData = {
      'date': '${_selectedDate.year.toString().padLeft(4, '0')}-'
          '${_selectedDate.month.toString().padLeft(2, '0')}-'
          '${_selectedDate.day.toString().padLeft(2, '0')}',
      'mealType': _selectedMealType!,
      'mainDish': _mainDishController.text.trim(),
      'subDish': _subDishController.text.trim().isEmpty ? null : _subDishController.text.trim(),
    };

    setState(() => _saving = true);
    try {
      final created = await ApiService.saveDietLog(user.id, newDietData);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onAddDietLog(created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('식단 기록 저장에 실패했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _mainDishController.dispose();
    _subDishController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomPadding + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('새 식단 기록', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: Text('날짜: ${_selectedDate.year}.${_selectedDate.month}.${_selectedDate.day}')),
                TextButton(onPressed: _presentDatePicker, child: const Text('날짜 변경')),
              ],
            ),

            DropdownButtonFormField<String>(
              value: _selectedMealType,
              decoration: const InputDecoration(labelText: '식사 시간'),
              items: const ['아침', '점심', '저녁']
                  .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedMealType = value),
              validator: (value) => value == null ? '식사 시간을 선택해주세요.' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _mainDishController,
              decoration: const InputDecoration(labelText: '메인 음식'),
              validator: (value) => value!.trim().isEmpty ? '메인 음식을 입력해주세요.' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _subDishController,
              decoration: const InputDecoration(labelText: '서브 음식'),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _submitForm,
              child: Text(_saving ? '저장 중...' : '저장하기'),
            ),
          ],
        ),
      ),
    );
  }
}
