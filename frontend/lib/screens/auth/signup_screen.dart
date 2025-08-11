import 'package:flutter/material.dart';
import 'package:smart_pad_app/services/api_service.dart';
import 'package:smart_pad_app/models/patient_model.dart'; // AgeRanges가 정의된 파일

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
  final _hospitalNameController = TextEditingController();

  // 상태 변수 선언
  UserRole _selectedRole = UserRole.patient;
  String? _sensoryPerception;
  String? _activityLevel;
  String? _movementLevel;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _ageRange;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _hospitalNameController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> userData = {
        'username': _usernameController.text,
        'password': _passwordController.text,
        'name': _nameController.text,
        'role': _selectedRole.name.toUpperCase(),
      };

      if (_selectedRole == UserRole.patient) {
        Map<String, dynamic> patientDetail = {
          'weight': double.tryParse(_weightController.text) ?? 0.0,
          'ageRange': _ageRange,
          'sensoryPerception': _sensoryPerception,
          'activityLevel': _activityLevel,
          'movementLevel': _movementLevel,
        };
        userData['patientDetail'] = patientDetail;
      } else if (_selectedRole == UserRole.admin) {
        Map<String, dynamic> adminDetail = {
          'hospitalName': _hospitalNameController.text,
        };
        userData['adminDetail'] = adminDetail;
      }

      try {
        await ApiService.signup(userData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해주세요.')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        print('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥');
        print('회원가입 실패! Flutter 앱에서 발생한 에러:');
        print(e);
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
                _buildRoleSelector(),
                const SizedBox(height: 30),

                _buildBasicInfoSection(),
                const SizedBox(height: 30),

                if (_selectedRole == UserRole.patient)
                  _buildPatientDetailSection(),
                if (_selectedRole == UserRole.admin)
                  _buildAdminDetailSection(),

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
          decoration: const InputDecoration(
            labelText: '아이디',
            border: OutlineInputBorder(),
            counterText: "",
          ),
          maxLength: 12,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '아이디를 입력해주세요.';
            }
            if (value.length > 12) {
              return '아이디는 12글자 이하로 입력해주세요.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
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
            RegExp passwordRegExp = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{1,12}$');
            if (!passwordRegExp.hasMatch(value)) {
              return '비밀번호는 영어, 숫자를 혼용해야 합니다.';
            }
            return null;
          },
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
            if (value == null || value.isEmpty) {
              return '비밀번호를 다시 한번 입력해주세요.';
            }
            if (value != _passwordController.text) {
              return '비밀번호가 일치하지 않습니다.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

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
    final fourStepItems = ['최상', '상', '중', '하'];
    final ageRangeOptions = [
      AgeRanges.age1_20,
      AgeRanges.age21_40,
      AgeRanges.age41_60,
      AgeRanges.age61_80,
      AgeRanges.age81_plus,
    ];

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
        DropdownButtonFormField<String>(
          value: _ageRange,
          decoration: const InputDecoration(labelText: '나이대', border: OutlineInputBorder()),
          items: ageRangeOptions.map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
          onChanged: (value) => setState(() => _ageRange = value),
          validator: (value) => value == null ? '나이대를 선택해주세요.' : null,
        ),
        const SizedBox(height: 16),
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

  Widget _buildAdminDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40, thickness: 1),
        const Text('관리자 상세 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _hospitalNameController,
          decoration: const InputDecoration(labelText: '병원 이름', border: OutlineInputBorder()),
          validator: (value) {
            if (_selectedRole == UserRole.admin && (value == null || value.isEmpty)) {
              return '병원 이름을 입력해주세요.';
            }
            return null;
          },
        ),
      ],
    );
  }
}