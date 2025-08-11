import 'package:flutter/material.dart';
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
    // 프레임 이후에 세션 복원 → 라우팅
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();

    // ✅ SharedPreferences에서 토큰+유저 복원 + ApiService에 토큰 재주입
    await auth.tryRestoreSession();

    if (!mounted) return;

    // 잠깐 로딩 표시 유지 (선택)
    await Future.delayed(const Duration(milliseconds: 300));

    if (auth.isLoggedIn) {
      final role = auth.user!.role;
      Navigator.of(context).pushReplacementNamed(
        role == UserRole.admin ? '/admin_main' : '/patient_main',
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/start');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
