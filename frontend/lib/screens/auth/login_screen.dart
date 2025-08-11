import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'package:smart_pad_app/providers/auth_provider.dart';
import 'package:smart_pad_app/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.patient; // UI 표시용 (서버 응답으로 실제 역할 결정)
  bool _isPasswordVisible = false;

  // 아이디 기억하기
  bool _rememberUsername = false;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadRememberedUsername();
  }

  Future<void> _loadRememberedUsername() async {
    final rememberedUsername = await _storage.read(key: 'rememberedUsername');
    if (!mounted) return;
    if (rememberedUsername != null) {
      setState(() {
        _usernameController.text = rememberedUsername;
        _rememberUsername = true;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      // 아이디 기억하기 저장/삭제
      if (_rememberUsername) {
        await _storage.write(key: 'rememberedUsername', value: username);
      } else {
        await _storage.delete(key: 'rememberedUsername');
      }

      // ✅ 중요: AuthProvider를 통해 로그인해야 SharedPreferences에 (token, user) 저장됨
      await context.read<AuthProvider>().login(username, password);

      if (!mounted) return;
      final user = context.read<AuthProvider>().user!;
      // 서버가 내려준 실제 역할로 분기
      if (user.role == UserRole.admin) {
        Navigator.pushReplacementNamed(context, '/admin_main');
      } else {
        Navigator.pushReplacementNamed(context, '/patient_main');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRoleSelector(),
                  const SizedBox(height: 30.0),

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: '아이디',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? '아이디를 입력해주세요.' : null,
                  ),
                  const SizedBox(height: 16.0),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? '비밀번호를 입력해주세요.' : null,
                  ),

                  _buildRememberUsernameCheckbox(),
                  const SizedBox(height: 20.0),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _login(context),
                    child: const Text('로그인'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return SegmentedButton<UserRole>(
      segments: const [
        ButtonSegment<UserRole>(
          value: UserRole.patient,
          label: Text('환자'),
          icon: Icon(Icons.personal_injury_outlined),
        ),
        ButtonSegment<UserRole>(
          value: UserRole.admin,
          label: Text('관리자'),
          icon: Icon(Icons.admin_panel_settings_outlined),
        ),
      ],
      selected: {_selectedRole},
      onSelectionChanged: (sel) => setState(() => _selectedRole = sel.first),
      style: SegmentedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildRememberUsernameCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: _rememberUsername,
          onChanged: (v) => setState(() => _rememberUsername = v ?? false),
        ),
        const Text('아이디 기억하기'),
      ],
    );
  }
}
