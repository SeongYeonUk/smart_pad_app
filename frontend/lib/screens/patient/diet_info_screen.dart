import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pad_app/models/user_model.dart';
import 'package:smart_pad_app/models/diet_log_model.dart';
import 'package:smart_pad_app/providers/auth_provider.dart';
import 'package:smart_pad_app/services/api_service.dart';
import 'dart:math';

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
      isScrollControlled: true, // Allows the modal to take up more screen space
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

  void _showEditDietLogModal(DietLogModel logToEdit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return AddDietLogForm(
          initialData: logToEdit,
          onAddDietLog: (updated) {
            // Update the list with the edited log
            setState(() {
              final index = _dietLogs.indexWhere((log) => log.id == updated.id);
              if (index != -1) {
                _dietLogs[index] = updated;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('식단 기록이 수정되었습니다.')),
            );
          },
          onDelete: (deletedLogId) {
            // Remove the deleted log from the list
            setState(() {
              _dietLogs.removeWhere((log) => log.id == deletedLogId);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('식단 기록이 삭제되었습니다.')),
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
              onTap: () => _showEditDietLogModal(log), // Added onTap for editing
              leading: _getMealIcon(log.mealType, theme),
              title: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '${d.year}.${d.month}.${d.day} (${log.mealType})',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (log.proteinGrams != null)
                      TextSpan(
                        text: '  단백질: ${log.proteinGrams}g',
                        style: theme.textTheme.bodyMedium, // Changed to bodyMedium
                      ),
                  ],
                ),
              ),
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

// ===== Additional form =====
enum ProteinInputMethod { manual, food, general }

class AddDietLogForm extends StatefulWidget {
  final DietLogModel? initialData; // Added initialData for editing
  final void Function(DietLogModel created) onAddDietLog;
  final void Function(int deletedLogId)? onDelete; // Callback for deletion

  const AddDietLogForm({
    super.key,
    this.initialData, // Made optional
    required this.onAddDietLog,
    this.onDelete, // Made optional
  });

  @override
  State<AddDietLogForm> createState() => _AddDietLogFormState();
}

class _AddDietLogFormState extends State<AddDietLogForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  String? _selectedMealType;
  final _mainDishController = TextEditingController();
  final _subDishController = TextEditingController();
  bool _saving = false;

  // New state variables for protein input
  ProteinInputMethod _proteinInputMethod = ProteinInputMethod.general; // Default to general
  final _manualProteinController = TextEditingController();
  String? _selectedFoodType;
  final _foodAmountController = TextEditingController();

  // Protein values per 100g
  static const Map<String, int> _foodProteinValues = {
    '돼지고기': 17,
    '소고기': 15,
    '닭고기': 30,
    '생선류': 23,
    '계란': 12,
    '유제품': 3,
    '콩류': 25,
    '견과류': 23,
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      // Initialize with existing data
      _selectedDate = widget.initialData!.date;
      _selectedMealType = widget.initialData!.mealType;
      _mainDishController.text = widget.initialData!.mainDish;
      if (widget.initialData!.subDish != null) {
        _subDishController.text = widget.initialData!.subDish!;
      }
      if (widget.initialData!.proteinGrams != null) {
        _proteinInputMethod = ProteinInputMethod.manual;
        _manualProteinController.text = widget.initialData!.proteinGrams!.toString();
      }
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _mainDishController.dispose();
    _subDishController.dispose();
    _manualProteinController.dispose();
    _foodAmountController.dispose();
    super.dispose();
  }

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

  int _calculateProtein() {
    switch (_proteinInputMethod) {
      case ProteinInputMethod.manual:
        final amount = int.tryParse(_manualProteinController.text);
        return amount ?? 0;
      case ProteinInputMethod.food:
        final foodGrams = int.tryParse(_foodAmountController.text);
        if (_selectedFoodType != null && foodGrams != null) {
          final proteinPer100g = _foodProteinValues[_selectedFoodType]!;
          return (foodGrams * proteinPer100g / 100).floor();
        }
        return 0;
      case ProteinInputMethod.general:
        return 18;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_proteinInputMethod == ProteinInputMethod.food && _selectedFoodType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('음식 종류를 선택해주세요.')),
      );
      return;
    }

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    final proteinGrams = _calculateProtein();

    final newDietData = {
      if (widget.initialData != null) 'id': widget.initialData!.id, // Include ID for updates
      'date': '${_selectedDate.year.toString().padLeft(4, '0')}-'
          '${_selectedDate.month.toString().padLeft(2, '0')}-'
          '${_selectedDate.day.toString().padLeft(2, '0')}',
      'mealType': _selectedMealType!,
      'mainDish': _mainDishController.text.trim(),
      'subDish': _subDishController.text.trim().isEmpty ? null : _subDishController.text.trim(),
      'proteinGrams': proteinGrams,
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

  Future<void> _deleteLog() async {
    if (widget.initialData?.id == null) return;

    setState(() => _saving = true);
    try {
      await ApiService.deleteDietLog(widget.initialData!.id!);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onDelete?.call(widget.initialData!.id!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('식단 기록 삭제에 실패했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.initialData != null ? '식단 수정' : '새 식단 기록', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            const Text('단백질 섭취량', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Column(
              children: ProteinInputMethod.values.map((method) {
                return RadioListTile<ProteinInputMethod>(
                  title: Text(_getProteinMethodLabel(method)),
                  value: method,
                  groupValue: _proteinInputMethod,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _proteinInputMethod = value);
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 12),
            if (_proteinInputMethod == ProteinInputMethod.manual)
              TextFormField(
                controller: _manualProteinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '단백질량 (g)',
                  suffixText: 'g',
                ),
                validator: (value) {
                  if (value!.isEmpty) return '단백질량을 입력해주세요.';
                  if (int.tryParse(value) == null) return '숫자를 입력해주세요.';
                  return null;
                },
              ),

            if (_proteinInputMethod == ProteinInputMethod.food)
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedFoodType,
                    decoration: const InputDecoration(labelText: '음식 종류'),
                    items: _foodProteinValues.keys
                        .map((food) => DropdownMenuItem(value: food, child: Text(food)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedFoodType = value),
                    validator: (value) => value == null ? '음식 종류를 선택해주세요.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _foodAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '섭취량 (g)',
                      suffixText: 'g',
                    ),
                    validator: (value) {
                      if (value!.isEmpty) return '섭취량을 입력해주세요.';
                      if (int.tryParse(value) == null) return '숫자를 입력해주세요.';
                      return null;
                    },
                  ),
                ],
              ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.initialData != null)
                  TextButton(
                    onPressed: _saving ? null : _deleteLog,
                    child: const Text('삭제하기', style: TextStyle(color: Colors.red)),
                  ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _submitForm,
                  child: Text(_saving ? '저장 중...' : '저장하기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getProteinMethodLabel(ProteinInputMethod method) {
    switch (method) {
      case ProteinInputMethod.manual:
        return '단백질량 수동입력';
      case ProteinInputMethod.food:
        return '음식별 선택';
      case ProteinInputMethod.general:
        return '일반가정식';
    }
  }
}
