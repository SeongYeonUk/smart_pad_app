import 'package:flutter/material.dart';

// 환자 데이터 모델 (간단한 버전)
class Patient {
  final String id;
  final String name;
  final String riskStatus; // "정상", "주의", "위험"
  final double riskScore;

  Patient({required this.id, required this.name, required this.riskStatus, required this.riskScore});
}

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  // TODO: 실제로는 서버(Firebase 등)에서 환자 목록을 받아와야 합니다.
  final List<Patient> patientList = [
    Patient(id: 'p001', name: '김철수', riskStatus: '위험', riskScore: 92.1),
    Patient(id: 'p002', name: '이영희', riskStatus: '주의', riskScore: 78.5),
    Patient(id: 'p003', name: '박민준', riskStatus: '정상', riskScore: 45.3),
    Patient(id: 'p004', name: '최유리', riskStatus: '정상', riskScore: 50.8),
  ];

  // 위험 상태에 따라 색상을 결정하는 함수
  Color _getRiskColor(String status) {
    switch (status) {
      case '위험':
        return Colors.red.shade700;
      case '주의':
        return Colors.orange.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 위험도 순으로 정렬
    patientList.sort((a, b) {
      if (a.riskStatus == '위험') return -1;
      if (b.riskStatus == '위험') return 1;
      if (a.riskStatus == '주의') return -1;
      if (b.riskStatus == '주의') return 1;
      return 0;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('관리자 - 환자 목록'),
        // TODO: 알림 목록을 볼 수 있는 아이콘 버튼 추가
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // TODO: 알림 화면으로 이동하는 로직 구현
              // Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen()));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('알림 화면으로 이동합니다.')),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: patientList.length,
        itemBuilder: (context, index) {
          final patient = patientList[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: Icon(
                Icons.person,
                color: _getRiskColor(patient.riskStatus),
                size: 40,
              ),
              title: Text(patient.name, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '상태: ${patient.riskStatus} / 점수: ${patient.riskScore}',
                style: TextStyle(color: _getRiskColor(patient.riskStatus)),
              ),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: 이 환자의 상세 정보 화면으로 이동하는 로직 구현
                // 상세 화면에서는 환자용 화면(PatientMainScreen)과 건강 정보 입력 화면을 볼 수 있게 구성
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${patient.name} 님의 상세 정보로 이동합니다.')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
