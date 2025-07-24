import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreen();
}

class _PatientMainScreen extends State<PatientMainScreen> {
  // 실제로는 블루투스를 통해 받아올 센서 데이터 (임시 데이터)
  double pressure = 75.0;
  double temperature = 36.5;
  double humidity = 45.0;

  @override
  void initState() {
    super.initState();
    // 2초마다 데이터를 갱신하는 시뮬레이션
    // TODO: 이 부분을 실제 아두이노 블루투스 데이터 수신 로직으로 대체해야 합니다.
    Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        pressure = 60 + Random().nextDouble() * 30; // 60~90 사이의 랜덤 값
        temperature = 36.0 + Random().nextDouble(); // 36.0~37.0 사이의 랜덤 값
        humidity = 40 + Random().nextDouble() * 10;  // 40~50 사이의 랜덤 값
      });
    });
  }

  // 위험도 점수에 따라 색상을 반환하는 함수
  Color getRiskColor(double value) {
    if (value > 85) return Colors.red;
    if (value > 70) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('욕창 위험도')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              // Stack을 사용해 이미지 위에 다른 위젯들을 올립니다.
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // TODO: 여기에 사람 모양 이미지를 넣으세요.
                  // Image.asset('assets/body_outline.png'),
                  Container(
                    color: Colors.grey[200],
                    child: Center(child: Text('사람 모양 이미지 영역')),
                  ),

                  // 등 부위 데이터 표시 (예시)
                  Positioned(
                    top: 150,
                    left: 0,
                    right: 0,
                    child: _buildSensorInfo('등', pressure),
                  ),
                  // 엉덩이 부위 데이터 표시 (예시)
                  Positioned(
                    top: 250,
                    left: 0,
                    right: 0,
                    child: _buildSensorInfo('엉덩이', 65.0), // 임시 값
                  ),
                ],
              ),
            ),
          ),
          // 하단에 전체 정보 표시
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('종합 위험도 점수: ${pressure.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: getRiskColor(pressure))),
                SizedBox(height: 20),
                Text('온도: ${temperature.toStringAsFixed(1)}°C', style: TextStyle(fontSize: 18)),
                Text('습도: ${humidity.toStringAsFixed(1)}%', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 각 부위별 센서 정보를 표시하는 위젯을 만드는 함수
  Widget _buildSensorInfo(String part, double value) {
    return Column(
      children: [
        Text(part, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        CircleAvatar(
          radius: 30,
          backgroundColor: getRiskColor(value),
          child: Text(
            value.toStringAsFixed(0),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
