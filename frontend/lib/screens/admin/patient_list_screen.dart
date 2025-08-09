import 'package:flutter/material.dart';
// 환자의 상세 정보를 보여줄 환자용 셸 화면을 import 합니다.
import 'package:smart_pad_app/screens/patient/patient_shell.dart';

// 가상의 환자 데이터 모델 (나중에는 서버에서 받아옵니다)
class DummyPatient {
  final int id;
  final String name;
  final String riskLevel; // 위험, 주의, 정상
  final double riskScore;

  DummyPatient({required this.id, required this.name, required this.riskLevel, required this.riskScore});
}

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  // TODO: 실제로는 서버 API를 호출하여 환자 목록을 받아와야 합니다.
  final List<DummyPatient> _patientList = [
    DummyPatient(id: 101, name: '김민준', riskLevel: '위험', riskScore: 88.5),
    DummyPatient(id: 102, name: '이서연', riskLevel: '주의', riskScore: 72.1),
    DummyPatient(id: 103, name: '박도윤', riskLevel: '정상', riskScore: 45.3),
    DummyPatient(id: 104, name: '최아린', riskLevel: '정상', riskScore: 33.8),
  ];

  // 위험도에 따라 다른 색상을 반환하는 함수
  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case '위험':
        return Colors.red.shade700;
      case '주의':
        return Colors.orange.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('담당 환자 목록'),
        actions: [
          // 환자 추가 버튼
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () {
              // TODO: 환자 코드로 환자를 추가하는 다이얼로그 또는 화면을 띄웁니다.
              print('환자 추가 버튼 클릭');
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _patientList.length,
        itemBuilder: (context, index) {
          final patient = _patientList[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: _getRiskColor(patient.riskLevel),
                child: Text(
                  patient.name.substring(0, 1), // 이름의 첫 글자
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text(
                '위험도: ${patient.riskLevel} / 점수: ${patient.riskScore}',
                style: TextStyle(color: _getRiskColor(patient.riskLevel)),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // 환자를 탭하면, 해당 환자의 상세 정보를 볼 수 있는 화면으로 이동
                // TODO: patient.id와 같은 실제 환자 정보를 PatientShell로 넘겨줘야 합니다.
                Navigator.of(context).push(
                  MaterialPageRoute(
                    // 관리자가 환자 정보를 보는 것이므로, 환자용 셸을 재사용
                    builder: (context) => const PatientShell(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
