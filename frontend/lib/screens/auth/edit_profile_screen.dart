import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_pad_app/models/user_model.dart';
import 'package:smart_pad_app/providers/auth_provider.dart';
import 'package:smart_pad_app/services/api_service.dart';
import 'package:smart_pad_app/models/patient_model.dart'; // AgeRanges

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();

  // 환자 전용
  final _weightController = TextEditingController();
  String? _ageRange;
  String? _sensoryPerception;
  String? _activityLevel;
  String? _movementLevel;

  // 관리자 전용
  final _hospitalNameController = TextEditingController();

  bool _isLoading = true;

  static const List<String> ageRangeOptions = AgeRanges.allRanges;
  static const List<String> fourStepItems = ['최상', '상', '중', '하'];

  @override
  void initState() {
    super.initState();
    _loadProfileDetails();
  }

  Future<void> _loadProfileDetails() async {
    try {
      Map<String, dynamic> detail = {};
      if (widget.user.role == UserRole.patient) {
        detail = await ApiService.fetchPatientDetail(widget.user.id);
      } else if (widget.user.role == UserRole.admin) {
        detail = await ApiService.fetchAdminDetail(widget.user.id);
      }

      setState(() {
        _nameController.text = (detail['name'] as String?) ?? widget.user.name;

        if (widget.user.role == UserRole.patient) {
          _weightController.text = detail['weight'] != null ? '${detail['weight']}' : '';
          _ageRange = detail['ageRange'] as String?;
          _sensoryPerception = detail['sensoryPerception'] as String?;
          _activityLevel = detail['activityLevel'] as String?;
          _movementLevel = detail['movementLevel'] as String?;
        } else if (widget.user.role == UserRole.admin) {
          _hospitalNameController.text = (detail['hospitalName'] as String?) ?? '';
        }

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('정보를 불러오는 데 실패했습니다: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    final Map<String, dynamic> updateData = {'name': _nameController.text};

    if (widget.user.role == UserRole.patient) {
      updateData['patientDetail'] = {
        'weight': double.tryParse(_weightController.text),
        'ageRange': _ageRange,
        'sensoryPerception': _sensoryPerception,
        'activityLevel': _activityLevel,
        'movementLevel': _movementLevel,
      };
    } else if (widget.user.role == UserRole.admin) {
      updateData['adminDetail'] = {
        'hospitalName': _hospitalNameController.text,
      };
    }

    try {
      await ApiService.updateProfile(widget.user.id, updateData);

      if (mounted) {
        final updatedUser = UserModel(
          id: widget.user.id,
          username: widget.user.username,
          name: _nameController.text,
          role: widget.user.role,
        );
        Provider.of<AuthProvider>(context, listen: false).setUser(updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('개인정보가 성공적으로 변경되었습니다.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('변경에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = widget.user.role == UserRole.patient;
    final isAdmin = widget.user.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('개인정보 변경')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름'),
              ),
              const SizedBox(height: 20),

              if (isPatient) _buildPatientFields(),
              if (isAdmin) _buildAdminFields(),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientFields() {
    return Column(
      children: [
        TextFormField(
          controller: _weightController,
          decoration: const InputDecoration(labelText: '체중 (kg)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _ageRange,
          decoration: const InputDecoration(labelText: '나이대'),
          items: ageRangeOptions
              .map((label) => DropdownMenuItem(value: label, child: Text(label)))
              .toList(),
          onChanged: (v) => setState(() => _ageRange = v),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _sensoryPerception,
          decoration: const InputDecoration(labelText: '감각인지'),
          items: fourStepItems
              .map((label) => DropdownMenuItem(value: label, child: Text(label)))
              .toList(),
          onChanged: (v) => setState(() => _sensoryPerception = v),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _activityLevel,
          decoration: const InputDecoration(labelText: '활동량'),
          items: fourStepItems
              .map((label) => DropdownMenuItem(value: label, child: Text(label)))
              .toList(),
          onChanged: (v) => setState(() => _activityLevel = v),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _movementLevel,
          decoration: const InputDecoration(labelText: '운동량'),
          items: fourStepItems
              .map((label) => DropdownMenuItem(value: label, child: Text(label)))
              .toList(),
          onChanged: (v) => setState(() => _movementLevel = v),
        ),
      ],
    );
  }

  Widget _buildAdminFields() {
    return Column(
      children: [
        TextFormField(
          controller: _hospitalNameController,
          decoration: const InputDecoration(labelText: '병원 이름'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _hospitalNameController.dispose();
    super.dispose();
  }
}
