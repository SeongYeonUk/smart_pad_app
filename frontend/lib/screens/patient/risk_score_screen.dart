import 'package:flutter/material.dart';

class RiskScoreScreen extends StatelessWidget {
  const RiskScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('욕창 위험도'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. 센서 데이터 표시 영역
            _buildSensorDataSection(),
            const SizedBox(height: 20),

            // 2. 사람 모양 UI 영역
            Expanded(child: _buildBodyUISection()),

            const SizedBox(height: 20),

            // 3. 낙상 위험도 표시 영역
            _buildFallRiskSection(),
          ],
        ),
      ),
    );
  }

  // 각 섹션을 별도의 함수(메서드)로 분리하면 코드가 깔끔해집니다.
  Widget _buildSensorDataSection() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('압력: 75.0', style: TextStyle(fontSize: 16)),
            Text('온도: 36.5°C', style: TextStyle(fontSize: 16)),
            Text('습도: 45%', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyUISection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        // TODO: 여기에 실제 사람 모양 이미지를 배경으로 넣으면 좋습니다.
        // image: DecorationImage(image: AssetImage('assets/body_outline.png'), fit: BoxFit.contain)
      ),
      // Stack을 사용해 위젯들을 겹칩니다.
      child: Stack(
        children: [
          // 예시: 등 부위에 '위험' 상태 표시
          Positioned(
            top: 80, // 위에서부터의 거리
            left: 0,
            right: 0,
            child: _buildRiskIndicator('등', '위험'),
          ),
          // 예시: 엉덩이 부위에 '주의' 상태 표시
          Positioned(
            top: 150,
            left: 0,
            right: 0,
            child: _buildRiskIndicator('엉덩이', '주의'),
          ),
          // TODO: 다른 부위들(어깨, 발꿈치 등)도 추가
        ],
      ),
    );
  }

  // 부위별 위험도를 표시하는 작은 위젯
  Widget _buildRiskIndicator(String part, String riskLevel) {
    Color color;
    switch (riskLevel) {
      case '위험': color = Colors.red; break;
      case '주의': color = Colors.orange; break;
      default: color = Colors.green;
    }
    return Column(
      children: [
        Text(part, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: 15,
          backgroundColor: color.withOpacity(0.8),
          child: Text(riskLevel[0], style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildFallRiskSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text(
            '낙상 위험도: 주의 단계',
            style: TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
