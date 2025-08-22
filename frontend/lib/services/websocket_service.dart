import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart'; // ← headers를 쓰려면 IOWebSocketChannel 필요
import 'package:smart_pad_app/models/sensor_data_model.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  // ===== 환경설정: 네 서버 환경에 맞게 수정 =====
  static const String _wsUrl = 'ws://10.0.2.2:8080/ws'; // Spring WS 엔드포인트
  static const String _subscribeDestination = '/app/subscribe';
  static const String _topicBase = '/topic/sensordata'; // 최종 토픽: "$_topicBase" 또는 "$_topicBase/$patientId"

  /// (기존 방식 유지) 환자 ID로만 구독
  /// 서버가 patientId로 토픽을 나눌 때 사용.
  Stream<SensorData>? connect(int patientId) {
    try {
      final uri = Uri.parse(_wsUrl);
      _channel = IOWebSocketChannel.connect(uri); // 헤더 필요 없으니 기본 연결

      _subscribe(patientId: patientId);

      return _mapStreamToSensorData(_channel!.stream);
    } catch (e) {
      print('WebSocket 연결 오류(connect): $e');
      return null;
    }
  }

  /// (권장) JWT 인증으로 구독
  /// - 서버가 핸드셰이크의 Authorization 헤더를 읽어 인증 사용자 기준으로 권한/토픽을 결정하는 경우 사용.
  /// - 기존 토픽 규칙이 /topic/sensordata/{patientId}라면 patientId를 넣어주고,
  ///   인증 사용자 전용 토픽(/user/queue/...)나 공통 토픽(/topic/sensordata)이라면 생략 가능.
  Stream<SensorData>? connectWithToken({
    required String jwt,
    int? patientId,
  }) {
    try {
      final uri = Uri.parse(_wsUrl);
      _channel = IOWebSocketChannel.connect(
        uri,
        headers: {'Authorization': 'Bearer $jwt'},
      );

      _subscribe(patientId: patientId);

      return _mapStreamToSensorData(_channel!.stream);
    } catch (e) {
      print('WebSocket 연결 오류(connectWithToken): $e');
      return null;
    }
  }

  /// 공통 구독 메시지 전송
  void _subscribe({int? patientId}) {
    // 서버가 요구하는 구독 토픽 규칙에 맞춰 조립
    // 예) /topic/sensordata 또는 /topic/sensordata/{patientId}
    final topic =
    (patientId == null) ? _topicBase : '$_topicBase/$patientId';

    final subscribeMessage = {
      "destination": _subscribeDestination,
      "payload": topic,
    };
    _channel!.sink.add(jsonEncode(subscribeMessage));
  }

  /// 서버가 보내는 메시지를 SensorData로 변환
  Stream<SensorData> _mapStreamToSensorData(Stream<dynamic> stream) {
    return stream.map((dynamic data) {
      try {
        // 1) 문자열이면 JSON으로 파싱
        final parsed = (data is String) ? jsonDecode(data) : data;

        // 2) 일부 브로커/핸들러는 {"type":"MESSAGE","body":"{...}"} 형태로 보낼 수 있음 → body 우선 파싱
        if (parsed is Map<String, dynamic>) {
          if (parsed.containsKey('body')) {
            final body = parsed['body'];
            final inner = (body is String) ? jsonDecode(body) : body;
            return SensorData.fromJson(inner as Map<String, dynamic>);
          }
          // 3) 곧장 센서 JSON일 수도 있음
          return SensorData.fromJson(parsed);
        }

        // 4) 예상치 못한 형태면 에러
        throw FormatException('Unsupported WS message format: $parsed');
      } catch (e) {
        print('WebSocket 수신 파싱 오류: $e, raw=$data');
        // 파싱 실패 시, 적절히 기본값/무시 중 선택. 여기선 예외 던져 스트림 에러로 전달하지 않고
        // 임의 기본값을 리턴하거나, throw로 스트림 에러를 발생시킬 수 있음.
        // 안전하게 throw 해서 상위 onError로 넘김:
        throw e;
      }
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
