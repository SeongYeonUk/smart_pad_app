import 'package:flutter/material.dart';

// UserRole enum은 login_screen.dart와 중복되므로,
// 나중에 별도의 파일(예: lib/models/user_model.dart)로 옮기는 것이 좋습니다.
enum UserRole { patient, admin }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // 컨트롤러 선언
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  // 상태 변수 선언
  UserRole _selectedRole = UserRole.patient;
  String? _sensoryPerception; // 드롭다운 선택 값
  String? _activityLevel;
  String? _movementLevel;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    // 모든 컨트롤러 리소스 해제
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _signup() {
    if (_formKey.currentState!.validate()) {
      // TODO: 여기에 Spring 백엔드로 회원가입 요청을 보내는 API 호출 코드를 작성합니다.
      print('회원가입 시도:');
      print('역할: ${_selectedRole.name}');
      print('아이디: ${_usernameController.text}');
      print('비밀번호: ${_passwordController.text}');
      print('이름: ${_nameController.text}');

      if (_selectedRole == UserRole.patient) {
        print('체중: ${_weightController.text}');
        print('나이: ${_ageController.text}');
        print('감각인지: $_sensoryPerception');
        print('활동량: $_activityLevel');
        print('운동량: $_movementLevel');
      }

      // 회원가입 성공 후 로그인 화면으로 이동하라는 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해주세요.')),
      );
      // 현재 화면을 닫고 이전 화면(로그인/시작)으로 돌아감
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 기본 구분창 (환자/관리자)
                _buildRoleSelector(),
                const SizedBox(height: 30),

                // 2. 기본 정보창 (아이디, 비밀번호, 이름)
                _buildBasicInfoSection(),
                const SizedBox(height: 30),

                // 3. 환자 상세 정보창 (환자 선택 시에만 보임)
                if (_selectedRole == UserRole.patient)
                  _buildPatientDetailSection(),

                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _signup,
                  child: const Text('가입하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 각 섹션을 만드는 위젯 함수들 ---

  Widget _buildRoleSelector() {
    return SegmentedButton<UserRole>(
      segments: const [
        ButtonSegment<UserRole>(value: UserRole.patient, label: Text('환자 가입')),
        ButtonSegment<UserRole>(value: UserRole.admin, label: Text('관리자 가입')),
      ],
      selected: {_selectedRole},
      onSelectionChanged: (Set<UserRole> newSelection) {
        setState(() {
          _selectedRole = newSelection.first;
        });
      },
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('기본 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(labelText: '아이디', border: OutlineInputBorder()),
          validator: (value) => value!.trim().isEmpty ? '아이디를 입력해주세요.' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: '비밀번호',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          validator: (value) => value!.isEmpty ? '비밀번호를 입력해주세요.' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: InputDecoration(
            labelText: '비밀번호 확인',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            ),
          ),
          validator: (value) {
            if (value!.isEmpty) return '비밀번호를 다시 한번 입력해주세요.';
            if (value != _passwordController.text) return '비밀번호가 일치하지 않습니다.';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: '이름', border: OutlineInputBorder()),
          validator: (value) => value!.trim().isEmpty ? '이름을 입력해주세요.' : null,
        ),
      ],
    );
  }

  Widget _buildPatientDetailSection() {
    // 드롭다운 메뉴 아이템 리스트
    final fourStepItems = ['최상', '상', '중', '하'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40, thickness: 1),
        const Text('환자 상세 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _weightController,
          decoration: const InputDecoration(labelText: '체중 (kg)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          validator: (value) => value!.isEmpty ? '체중을 입력해주세요.' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _ageController,
          decoration: const InputDecoration(labelText: '나이', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          validator: (value) => value!.isEmpty ? '나이를 입력해주세요.' : null,
        ),
        const SizedBox(height: 16),
        // 드롭다운 버튼들
        DropdownButtonFormField<String>(
          value: _sensoryPerception,
          decoration: const InputDecoration(labelText: '감각인지', border: OutlineInputBorder()),
          items: fourStepItems.map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
          onChanged: (value) => setState(() => _sensoryPerception = value),
          validator: (value) => value == null ? '감각인지 정도를 선택해주세요.' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _activityLevel,
          decoration: const InputDecoration(labelText: '활동량', border: OutlineInputBorder()),
          items: fourStepItems.map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
          onChanged: (value) => setState(() => _activityLevel = value),
          validator: (value) => value == null ? '활동량을 선택해주세요.' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _movementLevel,
          decoration: const InputDecoration(labelText: '운동량', border: OutlineInputBorder()),
          items: fourStepItems.map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
          onChanged: (value) => setState(() => _movementLevel = value),
          validator: (value) => value == null ? '운동량을 선택해주세요.' : null,
        ),
      ],
    );
  }
}
