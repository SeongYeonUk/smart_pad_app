import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:smart_pad_app/providers/auth_provider.dart';
import 'package:smart_pad_app/models/user_model.dart';
import 'package:smart_pad_app/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.patient;
  bool _isPasswordVisible = false;

  // 아이디 기억하기 관련 변수
  bool _rememberUsername = false;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadRememberedUsername(); // 화면 시작 시 저장된 아이디 불러오기
  }

  // 기기에 저장된 아이디를 불러와 입력창에 채우는 함수
  Future<void> _loadRememberedUsername() async {
    final rememberedUsername = await _storage.read(key: 'rememberedUsername');
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

  // 로그인 로직 전체
  void _login(BuildContext context) async {
    print("--- 1. 로그인 버튼 눌림 ---");
    if (_formKey.currentState!.validate()) {
      print("--- 2. 유효성 검사 통과 ---");
      final username = _usernameController.text;
      final password = _passwordController.text;

      try {
        print("--- 3. ApiService.login 호출 시도 ---");

        // 아이디 기억하기 체크박스 상태에 따라 아이디를 저장하거나 삭제
        if (_rememberUsername) {
          await _storage.write(key: 'rememberedUsername', value: username);
        } else {
          await _storage.delete(key: 'rememberedUsername');
        }

        // 실제 로그인 API 호출
        final responseData = await ApiService.login(username, password);

        print("--- 4. ApiService.login 호출 성공! ---");
        print("   - 서버 응답: $responseData");

        // 자동 로그인을 위해 사용자 정보 전체를 기기에 저장
        final userJson = jsonEncode(responseData['user']);
        await _storage.write(key: 'loggedInUser', value: userJson);

        // 서버 응답을 UserModel 객체로 변환
        final realUser = UserModel.fromJson(responseData['user']);

        if (!mounted) return;

        // Provider에 사용자 정보를 저장하여 앱의 로그인 상태를 업데이트
        Provider.of<AuthProvider>(context, listen: false).setUser(realUser);
        print("--- 5. Provider에 사용자 정보 저장 완료 ---");

        // 역할에 따라 다른 메인 화면으로 이동
        if (realUser.role == UserRole.patient) {
          Navigator.pushReplacementNamed(context, '/patient_main');
        } else {
          Navigator.pushReplacementNamed(context, '/admin_main');
        }
        print("--- 6. 화면 이동 완료 ---");

      } catch (e) {
        // 에러 발생 시 디버깅 정보와 사용자 피드백 표시
        print("--- ❗️❗️❗️ 에러 발생 ❗️❗️❗️ ---");
        print("   - 에러 타입: ${e.runtimeType}");
        print("   - 에러 내용: $e");
        print("--- ❗️❗️❗️ ---");

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
        );
      }
    } else {
      print("--- ❗️❗️❗️ 유효성 검사 실패! ---");
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
                    decoration: const InputDecoration(labelText: '아이디', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                    validator: (value) => (value == null || value.trim().isEmpty) ? '아이디를 입력해주세요.' : null,
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
                    validator: (value) => (value == null || value.isEmpty) ? '비밀번호를 입력해주세요.' : null,
                  ),
                  _buildRememberUsernameCheckbox(), // 아이디 기억하기 체크박스
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
        ButtonSegment<UserRole>(value: UserRole.patient, label: Text('환자'), icon: Icon(Icons.personal_injury_outlined)),
        ButtonSegment<UserRole>(value: UserRole.admin, label: Text('관리자'), icon: Icon(Icons.admin_panel_settings_outlined)),
      ],
      selected: {_selectedRole},
      onSelectionChanged: (newSelection) => setState(() => _selectedRole = newSelection.first),
      style: SegmentedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), textStyle: const TextStyle(fontSize: 16)),
    );
  }

  // 아이디 기억하기 체크박스 위젯을 만드는 함수
  Widget _buildRememberUsernameCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: _rememberUsername,
          onChanged: (value) => setState(() => _rememberUsername = value ?? false),
        ),
        const Text('아이디 기억하기'),
      ],
    );
  }
}
