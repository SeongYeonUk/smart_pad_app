import 'package:flutter/material.dart';
// provider 패키지와 우리가 만들 AuthProvider를 import 합니다.
import 'package:provider/provider.dart';
import 'package:smart_pad_app/providers/auth_provider.dart';

// 만들어 둔 화면들을 모두 import 합니다.
import 'package:smart_pad_app/screens/auth/start_screen.dart';
import 'package:smart_pad_app/screens/auth/login_screen.dart';
import 'package:smart_pad_app/screens/auth/signup_screen.dart';
import 'package:smart_pad_app/screens/patient/patient_shell.dart';
import 'package:smart_pad_app/screens/admin/admin_shell.dart';

void main() {
  runApp(
    // 1. 앱 전체를 ChangeNotifierProvider로 감싸줍니다.
    //    이렇게 하면 앱의 어느 위젯에서든 AuthProvider에 접근할 수 있습니다.
    ChangeNotifierProvider(
      // 2. 앱이 시작될 때 AuthProvider 클래스의 인스턴스를 하나 생성합니다.
      //    이 인스턴스가 앱이 실행되는 동안 로그인 상태를 계속 기억하게 됩니다.
      create: (context) => AuthProvider(),
      // 3. 원래 있던 MyApp 위젯을 자식(child)으로 넣습니다.
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '스마트 욕창 방지 앱',
      theme: ThemeData(
        // primarySwatch 대신 colorScheme을 사용하는 것이 최신 방식입니다.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true, // 최신 머티리얼 디자인 적용
      ),
      // 앱이 시작될 때 보여줄 첫 화면
      initialRoute: '/start',
      // 앱의 전체 화면 지도 (네비게이션 경로)
      routes: {
        '/start': (context) => const StartScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/patient_main': (context) => const PatientShell(), // 환자용 메인
        '/admin_main': (context) => const AdminShell(),   // 관리자용 메인
      },
    );
  }
}
