import 'package:flutter/material.dart';
import 'package:smart_pad/screens/main_admin/admin_main_screen.dart';
import 'package:smart_pad/screens/main_patient/patient_main_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 사용자 유형(환자/관리자)을 선택하기 위한 상태
  // 0: 환자, 1: 관리자
  List<bool> _isSelected = [true, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('로그인'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 사용자 유형 선택
            ToggleButtons(
              isSelected: _isSelected,
              onPressed: (int index) {
                setState(() {
                  if (index == 0) {
                    _isSelected = [true, false];
                  } else {
                    _isSelected = [false, true];
                  }
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('환자'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('관리자'),
                ),
              ],
            ),
            SizedBox(height: 20),

            // 아이디/비밀번호 입력 필드
            TextField(
              decoration: InputDecoration(labelText: '아이디'),
            ),
            SizedBox(height: 10),
            TextField(
              obscureText: true, // 비밀번호 가리기
              decoration: InputDecoration(labelText: '비밀번호'),
            ),
            SizedBox(height: 40),

            // 로그인 버튼
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // 버튼 크기
              ),
              onPressed: () {
                // TODO: 여기에 실제 로그인 로직을 구현해야 합니다. (예: Firebase Authentication)
                // 지금은 선택된 사용자에 따라 다른 화면으로 이동만 시킵니다.

                bool isPatient = _isSelected[0];
                if (isPatient) {
                  // 환자 선택 시, 환자 메인 화면으로 이동
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => PatientMainScreen()),
                  );
                } else {
                  // 관리자 선택 시, 관리자 메인 화면으로 이동
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AdminMainScreen()),
                  );
                }
              },
              child: Text('로그인', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
