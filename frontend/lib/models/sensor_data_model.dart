class SensorData {
  final int pressure;
  final int temperature;
  final int humidity;
  final DateTime timestamp;

  SensorData({
    required this.pressure,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      pressure: json['pressure'] as int,
      temperature: json['temperature'] as int,
      humidity: json['humidity'] as int,
      // 백엔드에서 LocalDateTime 형태로 넘어온 문자열을 파싱합니다.
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}