import 'dart:convert'; // jsonEncode를 사용하기 위해 import 합니다.
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Secure Storage를 사용하기 위해 import 합니다.
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 로그인 함수는 BuildContext를 인자로 받습니다.
  void _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      try {
        // 1. ApiService를 통해 실제 로그인 요청을 보냅니다.
        final responseData = await ApiService.login(username, password);

        // --- ▼▼▼ [핵심] 로그인 정보 영구 저장 로직 추가 ▼▼▼ ---

        // 2. 기기에 데이터를 안전하게 저장하기 위한 storage 인스턴스를 생성합니다.
        const storage = FlutterSecureStorage();

        // 3. 서버가 보내준 사용자 정보 Map('user' 키 아래의 값)을 JSON 형태의 문자열로 변환합니다.
        final userJson = jsonEncode(responseData['user']);

        // 4. 'loggedInUser' 라는 키(key)로 변환된 사용자 정보 문자열을 기기에 안전하게 저장합니다.
        //    'await'를 사용하여 저장이 완료될 때까지 기다립니다.
        await storage.write(key: 'loggedInUser', value: userJson);

        // TODO: 실제 서비스에서는 responseData['token'] 값을 저장하여 API 요청 시마다 사용해야 합니다.
        // await storage.write(key: 'jwtToken', value: responseData['token']);

        // --- ▲▲▲ 여기까지 추가 ▲▲▲ ---

        // 5. 서버 응답을 UserModel 객체로 변환합니다.
        final realUser = UserModel.fromJson(responseData['user']);

        // 6. context가 유효한지 확인합니다. (비동기 작업 후 화면 이동 시 좋은 습관)
        if (!mounted) return;

        // 7. Provider에 '진짜' 사용자 정보를 저장하여 현재 앱 세션의 로그인 상태를 업데이트합니다.
        Provider.of<AuthProvider>(context, listen: false).setUser(realUser);

        // 8. 사용자의 역할에 따라 적절한 메인 화면으로 이동합니다.
        if (realUser.role == UserRole.patient) {
          Navigator.pushReplacementNamed(context, '/patient_main');
        } else {
          Navigator.pushReplacementNamed(context, '/admin_main');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '아이디를 입력해주세요.';
                      }
                      return null;
                    },
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
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      _login(context);
                    },
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
      segments: const <ButtonSegment<UserRole>>[
        ButtonSegment<UserRole>(
            value: UserRole.patient,
            label: Text('환자'),
            icon: Icon(Icons.personal_injury_outlined)),
        ButtonSegment<UserRole>(
            value: UserRole.admin,
            label: Text('관리자'),
            icon: Icon(Icons.admin_panel_settings_outlined)),
      ],
      selected: <UserRole>{_selectedRole},
      onSelectionChanged: (Set<UserRole> newSelection) {
        setState(() {
          _selectedRole = newSelection.first;
        });
      },
      style: SegmentedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
}
