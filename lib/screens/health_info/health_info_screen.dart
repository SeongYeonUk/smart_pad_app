import 'package:flutter/material.dart';

class HealthInfoScreen extends StatefulWidget {
  const HealthInfoScreen({super.key});

  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // 입력된 값을 저장할 컨트롤러
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _dietController = TextEditingController();

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _dietController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('건강 정보 입력')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('기본 정보', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 10),
                TextFormField(
                  controller: _heightController,
                  decoration: InputDecoration(labelText: '키 (cm)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(labelText: '몸무게 (kg)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(labelText: '나이', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 30),
                Text('일일 정보', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 10),
                TextFormField(
                  controller: _dietController,
                  decoration: InputDecoration(
                    labelText: '식단 정보 (예: 닭가슴살 100g)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    // TODO: 입력된 데이터를 데이터베이스(Firebase 등)에 저장하는 로직 구현
                    final height = _heightController.text;
                    final weight = _weightController.text;
                    final diet = _dietController.text;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('정보가 저장되었습니다: 키 $height, 몸무게 $weight, 식단: $diet')),
                    );
                    Navigator.pop(context); // 저장 후 이전 화면으로 돌아가기
                  },
                  child: Text('저장하기', style: TextStyle(fontSize: 18)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
