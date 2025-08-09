import 'package:flutter/material.dart';
import 'package:smart_pad_app/services/api_service.dart';

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

// signup_screen.dart 의 _signup() 함수
  void _signup() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> userData = {
        'username': _usernameController.text,
        'password': _passwordController.text,
        'name': _nameController.text,
        'role': _selectedRole.name.toUpperCase(),
      };

      try {
        await ApiService.signup(userData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해주세요.')),
        );
        Navigator.of(context).pop();

      } catch (e) {
        // --- ▼▼▼ 바로 이 부분입니다! ▼▼▼ ---
        print('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥');
        print('회원가입 실패! Flutter 앱에서 발생한 에러:');
        print(e); // 에러 객체 전체를 출력하여 자세한 정보 확인
        print('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 실패: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
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

  // signup_screen.dart 파일의 다른 부분은 그대로 두고,
// _buildBasicInfoSection 함수만 아래 내용으로 교체하세요.

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('기본 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // --- 아이디(username) 입력 필드 ---
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: '아이디',
            border: OutlineInputBorder(),
            counterText: "", // 글자 수 카운터 숨기기
          ),
          maxLength: 12, // 입력 가능한 최대 글자 수 제한
          validator: (value) {
            // 1. 입력값이 없는지 확인
            if (value == null || value.trim().isEmpty) {
              return '아이디를 입력해주세요.';
            }
            // 2. 최대 길이를 초과했는지 확인 (maxLength가 시각적으로 제한해주지만, 한번 더 검사)
            if (value.length > 12) {
              return '아이디는 12글자 이하로 입력해주세요.';
            }
            // 3. 모든 검사를 통과하면 null을 반환하여 유효하다고 알림
            return null;
          },
        ),
        const SizedBox(height: 16),

        // --- 비밀번호(password) 입력 필드 ---
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible, // 비밀번호 가리기
          decoration: InputDecoration(
            labelText: '비밀번호',
            border: const OutlineInputBorder(),
            counterText: "",
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          maxLength: 12,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '비밀번호를 입력해주세요.';
            }
            if (value.length > 12) {
              return '비밀번호는 12글자 이하로 입력해주세요.';
            }
            // 4. 정규 표현식(RegExp)을 사용하여 복잡한 규칙 검사
            //    - (?=.*[A-Za-z]): 최소 한 개의 영문자가 포함되어야 함
            //    - (?=.*\d): 최소 한 개의 숫자가 포함되어야 함
            RegExp passwordRegExp = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{1,12}$');
            if (!passwordRegExp.hasMatch(value)) {
              return '비밀번호는 영어, 숫자를 혼용해야 합니다.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // --- 비밀번호 확인 입력 필드 ---
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
            if (value == null || value.isEmpty) {
              return '비밀번호를 다시 한번 입력해주세요.';
            }
            // 5. 비밀번호 입력 필드의 값과 일치하는지 확인
            if (value != _passwordController.text) {
              return '비밀번호가 일치하지 않습니다.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // --- 이름(name) 입력 필드 ---
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: '이름', border: OutlineInputBorder()),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '이름을 입력해주세요.';
            }
            return null;
          },
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
