import 'package:flutter/material.dart';

// 1. Provider 패키지를 import 하여 앱 전체에서 상태 관리를 할 수 있도록 합니다.
import 'package:provider/provider.dart';
// 2. 우리가 만든 AuthProvider를 import 하여 로그인 상태를 관리합니다.
import 'package:smart_pad_app/providers/auth_provider.dart';

// 3. 앱에서 사용하는 모든 화면 위젯들을 import 합니다.
import 'package:smart_pad_app/screens/auth/splash_screen.dart'; // [추가] 앱의 첫 진입점이 될 스플래시 화면
import 'package:smart_pad_app/screens/auth/start_screen.dart';
import 'package:smart_pad_app/screens/auth/login_screen.dart';
import 'package:smart_pad_app/screens/auth/signup_screen.dart';
import 'package:smart_pad_app/screens/patient/patient_shell.dart';
import 'package:smart_pad_app/screens/admin/admin_shell.dart';

void main() {
  runApp(
    // ChangeNotifierProvider: 앱 전체 위젯 트리에 AuthProvider를 제공하는 '공급자' 역할을 합니다.
    // create: 앱이 시작될 때 AuthProvider 인스턴스를 딱 한 번 생성합니다.
    //         이 인스턴스가 앱이 실행되는 동안 로그인 상태를 계속 기억하게 됩니다.
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(), // MyApp과 그 하위의 모든 위젯들이 AuthProvider에 접근할 수 있게 됩니다.
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 디버그 모드에서 오른쪽 상단에 표시되는 "DEBUG" 배너를 숨깁니다.
      debugShowCheckedModeBanner: false,
      title: '스마트 욕창 방지 앱',
      theme: ThemeData(
        // 앱의 전체적인 색상 테마를 seedColor를 기반으로 조화롭게 생성합니다.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        // 최신 머티리얼 디자인 3를 활성화하여 UI를 더 세련되게 만듭니다.
        useMaterial3: true,
      ),

      // --- 화면 흐름(Navigation) 설정 ---

      // initialRoute: 앱이 시작될 때 가장 먼저 보여줄 화면의 경로를 지정합니다.
      // '/'는 앱의 가장 기본 경로를 의미하며, 여기에 SplashScreen을 연결합니다.
      initialRoute: '/',

      // routes: 앱의 전체 화면 '지도'입니다. 각 경로 이름에 해당하는 화면 위젯을 연결해 줍니다.
      //         Navigator.pushNamed(context, '/login') 처럼 경로 이름으로 쉽게 화면을 이동할 수 있습니다.
      routes: {
        '/': (context) => const SplashScreen(),      // 새로운 앱 진입점. 로그인 상태를 확인하고 올바른 화면으로 보내줍니다.
        '/start': (context) => const StartScreen(),   // 로그아웃 상태일 때 보여줄 시작 화면.
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/patient_main': (context) => const PatientShell(), // 환자로 로그인 시 보여줄 메인 화면.
        '/admin_main': (context) => const AdminShell(),   // 관리자로 로그인 시 보여줄 메인 화면.
      },
    );
  }
}
