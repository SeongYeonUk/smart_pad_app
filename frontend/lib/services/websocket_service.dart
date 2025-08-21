import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:smart_pad_app/models/sensor_data_model.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  // 로그인한 환자 ID를 받아서 WebSocket URL을 생성합니다.
  Stream<SensorData>? connect(int patientId) {
    try {
      final wsUrl = Uri.parse('ws://10.0.2.2:8080/ws');
      _channel = WebSocketChannel.connect(wsUrl);

      // WebSocket 브로커의 구독 경로.
      final subscribeMessage = {
        "destination": "/app/subscribe",
        "payload": "/topic/sensordata/$patientId"
      };

      _channel!.sink.add(jsonEncode(subscribeMessage));

      // Stream을 통해 실시간으로 센서 데이터를 받아 SensorData 객체로 변환하여 반환
      return _channel!.stream.map((data) {
        final Map<String, dynamic> json = jsonDecode(data);
        return SensorData.fromJson(json);
      });
    } catch (e) {
      print('WebSocket 연결 오류: $e');
      return null;
    }
  }

  void disconnect() {
    _channel?.sink.close();
  }
}