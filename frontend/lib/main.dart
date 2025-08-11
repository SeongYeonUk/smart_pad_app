import 'package:flutter/material.dart';

// Provider
import 'package:provider/provider.dart';
import 'package:smart_pad_app/providers/auth_provider.dart';

// Screens
import 'package:smart_pad_app/screens/auth/splash_screen.dart';
import 'package:smart_pad_app/screens/auth/start_screen.dart';
import 'package:smart_pad_app/screens/auth/login_screen.dart';
import 'package:smart_pad_app/screens/auth/signup_screen.dart';
import 'package:smart_pad_app/screens/patient/patient_shell.dart';
import 'package:smart_pad_app/screens/admin/admin_shell.dart';

// ▼ 추가: 부팅 시 토큰 주입을 위해
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_pad_app/services/api_service.dart';

Future<void> main() async {
  // Flutter 바인딩 초기화 (비동기 초기화 전에 필요)
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 앱 시작 전에 저장된 토큰을 읽어서 ApiService에 주입
  //    - 키 이름은 보편적으로 'auth_token' 사용 (스플래시/프로바이더에서 같은 키 쓰는지 확인)
  //    - 혹시 다른 키를 쓰면 아래 키 이름만 맞춰주면 됨
  final prefs = await SharedPreferences.getInstance();
  final restoredToken = prefs.getString('auth_token') ?? prefs.getString('token');
  if (restoredToken != null && restoredToken.isNotEmpty) {
    ApiService.setToken(restoredToken);
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(), // 기존 흐름 유지 (SplashScreen이 라우팅)
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '스마트 욕창 방지 앱',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/start': (context) => const StartScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/patient_main': (context) => const PatientShell(),
        '/admin_main': (context) => const AdminShell(),
      },
    );
  }
}
