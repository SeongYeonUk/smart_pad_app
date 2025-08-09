import 'package:flutter/material.dart';

// 가상의 식단 데이터 모델 (나중에는 서버에서 받아옵니다)
class DummyDietLog {
  final DateTime date;
  final String mealType; // 아침, 점심, 저녁
  final String mainDish;
  final String subDish;

  DummyDietLog({
    required this.date,
    required this.mealType,
    required this.mainDish,
    required this.subDish,
  });
}

class DietInfoScreen extends StatefulWidget {
  const DietInfoScreen({super.key});

  @override
  State<DietInfoScreen> createState() => _DietInfoScreenState();
}

class _DietInfoScreenState extends State<DietInfoScreen> {
  // TODO: 실제로는 서버 API를 호출하여 식단 기록을 받아와야 합니다.
  final List<DummyDietLog> _dietLogs = [
    DummyDietLog(date: DateTime(2025, 7, 26), mealType: '아침', mainDish: '흰죽', subDish: '계란찜'),
    DummyDietLog(date: DateTime(2025, 7, 26), mealType: '점심', mainDish: '소고기 야채죽', subDish: '두부조림'),
    DummyDietLog(date: DateTime(2025, 7, 25), mealType: '저녁', mainDish: '닭가슴살 샐러드', subDish: '우유'),
    DummyDietLog(date: DateTime(2025, 7, 25), mealType: '점심', mainDish: '전복죽', subDish: '장조림'),
    DummyDietLog(date: DateTime(2025, 7, 25), mealType: '아침', mainDish: '누룽지', subDish: '동치미'),
  ];

  // 새 식단 입력을 위해 별도의 화면(Modal)을 띄우는 함수
  void _showAddDietLogModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // isScrollControlled: 키보드가 올라올 때 화면이 가려지지 않게 함
      isScrollControlled: true,
      builder: (ctx) {
        // 별도의 위젯으로 분리하여 코드 관리 용이
        return const AddDietLogForm();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식생활 정보'),
      ),
      body: ListView.builder(
        itemCount: _dietLogs.length,
        itemBuilder: (context, index) {
          final log = _dietLogs[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: _getMealIcon(log.mealType),
              title: Text('${log.date.year}.${log.date.month}.${log.date.day} (${log.mealType})'),
              subtitle: Text('주요리: ${log.mainDish}, 부요리: ${log.subDish}'),
              // TODO: 탭하면 수정/삭제 기능 추가 가능
              onTap: () {},
            ),
          );
        },
      ),
      // 오른쪽 하단의 + 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDietLogModal(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // 식사 시간에 따라 다른 아이콘을 보여주는 함수
  Widget _getMealIcon(String mealType) {
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
    return Icon(iconData, color: Theme.of(context).primaryColor);
  }
}


// --- 새 식단을 입력하는 폼 위젯 (별도로 분리) ---

class AddDietLogForm extends StatefulWidget {
  const AddDietLogForm({super.key});

  @override
  State<AddDietLogForm> createState() => _AddDietLogFormState();
}

class _AddDietLogFormState extends State<AddDietLogForm> {
  final _formKey = GlobalKey<FormState>();

  // 입력 값을 저장할 변수
  DateTime _selectedDate = DateTime.now();
  String? _selectedMealType;
  final _mainDishController = TextEditingController();
  final _subDishController = TextEditingController();

  // 날짜 선택기를 띄우는 함수
  Future<void> _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // TODO: 여기에 서버로 데이터를 전송하는 API 호출 로직 추가
      print('날짜: $_selectedDate');
      print('시간: $_selectedMealType');
      print('주요리: ${_mainDishController.text}');
      print('부요리: ${_subDishController.text}');

      Navigator.of(context).pop(); // 폼 닫기
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
    // 키보드 영역을 제외한 나머지 패딩을 계산
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      // 키보드가 올라올 때도 UI가 밀려 올라가도록 패딩 조정
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomPadding + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min, // 내용물 크기에 맞게 높이 조절
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('새 식단 기록', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // 날짜 선택
            Row(
              children: [
                Expanded(child: Text('날짜: ${_selectedDate.year}.${_selectedDate.month}.${_selectedDate.day}')),
                TextButton(onPressed: _presentDatePicker, child: const Text('날짜 변경')),
              ],
            ),

            // 아침/점심/저녁 선택
            DropdownButtonFormField<String>(
              value: _selectedMealType,
              decoration: const InputDecoration(labelText: '식사 시간'),
              items: ['아침', '점심', '저녁'].map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
              onChanged: (value) => setState(() => _selectedMealType = value),
              validator: (value) => value == null ? '식사 시간을 선택해주세요.' : null,
            ),
            const SizedBox(height: 12),

            // 주요리/부요리 입력
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
              onPressed: _submitForm,
              child: const Text('저장하기'),
            ),
          ],
        ),
      ),
    );
  }
}
