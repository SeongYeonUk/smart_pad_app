import 'dart:convert'; // jsonDecode를 사용하기 위해 import 합니다.
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Secure Storage를 사용하기 위해 import 합니다.
import 'package:provider/provider.dart';
import 'package:smart_pad_app/models/user_model.dart';
import 'package:smart_pad_app/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 위젯이 화면에 그려진 직후에 자동 로그인 로직을 실행합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatusAndNavigate();
    });
  }

  // 앱 시작 시 로그인 상태를 확인하고 적절한 화면으로 이동시키는 함수
  Future<void> _checkLoginStatusAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // --- ▼▼▼ [핵심] '자동 로그인' 로직 추가 ▼▼▼ ---

    try {
      // 1. 기기에 데이터가 저장되어 있는지 확인하기 위해 storage 인스턴스를 생성합니다.
      const storage = FlutterSecureStorage();

      // 2. 'loggedInUser' 키로 저장된 사용자 정보(JSON 문자열)를 읽어옵니다.
      //    저장된 값이 없으면 userJson은 null이 됩니다.
      final userJson = await storage.read(key: 'loggedInUser');

      // 3. 저장된 사용자 정보가 있다면 (즉, 이전에 로그인한 적이 있다면)
      if (userJson != null) {
        // 3-1. 읽어온 JSON 문자열을 다시 Map 형태로 변환(디코딩)합니다.
        final userData = jsonDecode(userJson);
        // 3-2. Map 데이터를 UserModel 객체로 변환합니다.
        final user = UserModel.fromJson(userData);
        // 3-3. AuthProvider에 사용자 정보를 설정하여 앱의 상태를 '로그인' 상태로 만듭니다.
        authProvider.setUser(user);
      }
      // 4. 저장된 정보가 없다면 아무것도 하지 않습니다. (AuthProvider는 로그아웃 상태 유지)

    } catch (e) {
      // 저장된 데이터를 읽거나 파싱하는 중 에러가 발생할 경우를 대비
      print('자동 로그인 처리 중 에러 발생: $e');
      // 안전을 위해 저장된 정보를 모두 삭제할 수도 있습니다.
      // await const FlutterSecureStorage().deleteAll();
    }

    // --- ▲▲▲ 여기까지 추가 ▲▲▲ ---


    // 잠시 기다려서 사용자가 로딩 화면을 인지할 수 있도록 합니다.
    await Future.delayed(const Duration(milliseconds: 500));

    // 이제 isLoggedIn 상태는 기기에 저장된 정보를 반영한 최종 상태가 됩니다.
    // context가 유효한지 확인하고 화면을 이동합니다.
    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      final userRole = authProvider.user!.role;
      if (userRole == UserRole.patient) {
        Navigator.pushReplacementNamed(context, '/patient_main');
      } else {
        Navigator.pushReplacementNamed(context, '/admin_main');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/start');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중임을 나타내는 간단한 UI
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
