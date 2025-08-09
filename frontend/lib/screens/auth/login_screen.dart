import 'package:flutter/material.dart';
// Provider와 AuthProvider, UserModel을 사용하기 위해 import 합니다.
import 'package:provider/provider.dart';
import 'package:smart_pad_app/providers/auth_provider.dart';
import 'package:smart_pad_app/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form 위젯을 제어하기 위한 GlobalKey
  final _formKey = GlobalKey<FormState>();

  // 아이디와 비밀번호 입력 값을 가져오기 위한 컨트롤러
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // 사용자 유형(환자/관리자)을 선택하기 위한 상태 변수
  UserRole _selectedRole = UserRole.patient;

  // 비밀번호를 보이게 할지 여부를 제어하는 변수
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    // 화면이 종료될 때 컨트롤러의 리소스를 해제합니다.
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- [핵심 수정] 로그인 버튼을 눌렀을 때 실행될 함수 ---
  void _login() {
    // 1. Form의 유효성 검사를 통과했는지 확인
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      // final password = _passwordController.text; // 나중에 실제 서버 통신 시 사용
      final role = _selectedRole;

      // 2. [가짜 데이터 생성] 실제로는 서버 API 응답으로 받게 될 UserModel 객체를 만듭니다.
      final dummyUser = UserModel(
        id: 1, // 임시 ID
        username: username,
        name: role == UserRole.patient ? '김환자' : '박관리', // 역할에 따라 다른 이름 부여
        role: role,
      );

      // 3. [상태 업데이트] Provider를 통해 AuthProvider에 접근하고, setUser 함수를 호출하여 로그인 상태를 앱 전체에 알립니다.
      //    listen: false는 이 함수 내에서는 UI를 다시 그릴 필요가 없다는 의미입니다. (단순히 함수만 호출)
      Provider.of<AuthProvider>(context, listen: false).setUser(dummyUser);

      // 4. [화면 이동] 역할에 따라 다른 메인 화면으로 이동합니다.
      if (role == UserRole.patient) {
        // pushReplacementNamed: 현재 화면을 없애고 새 화면으로 이동하여 뒤로가기 버튼으로 돌아오지 못하게 합니다.
        Navigator.pushReplacementNamed(context, '/patient_main');
      } else {
        Navigator.pushReplacementNamed(context, '/admin_main');
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
                  // 1. 사용자 역할 선택 (환자/관리자)
                  _buildRoleSelector(),
                  const SizedBox(height: 30.0),

                  // 2. 아이디 입력 필드
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

                  // 3. 비밀번호 입력 필드
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
                          // [수정] setState를 호출하여 비밀번호 보이기/숨기기 상태만 변경
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

                  // 4. 로그인 버튼
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _login, // 버튼을 누르면 _login 함수 실행
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

  // 사용자 역할(환자/관리자)을 선택하는 위젯을 만드는 함수
  Widget _buildRoleSelector() {
    return SegmentedButton<UserRole>(
      segments: const <ButtonSegment<UserRole>>[
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
