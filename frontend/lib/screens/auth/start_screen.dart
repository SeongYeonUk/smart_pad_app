import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TODO: 여기에 앱 로고나 제목을 추가하면 좋습니다.
                const Spacer(flex: 2),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    // 1단계에서 설정한 '/login' 경로로 이동
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text('로그인', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.grey[700], // 버튼 색상 변경
                  ),
                  onPressed: () {
                    // 1단계에서 설정한 '/signup' 경로로 이동
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text('회원가입', style: TextStyle(fontSize: 18)),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
