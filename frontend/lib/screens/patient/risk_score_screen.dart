import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:smart_pad_app/services/bluetooth_service.dart';
import 'package:smart_pad_app/screens/bluetooth/bluetooth_scan_screen.dart';

enum BluetoothConnectionState { disconnected, connecting, connected, failed }

class RiskScoreScreen extends StatefulWidget {
  // --- [핵심 1] 부모에게 상태 변경을 알릴 콜백 함수를 받기 위한 변수 ---
  final VoidCallback onStateChanged;

  // 생성자에서 key와 콜백 함수를 필수로 받도록 수정합니다.
  const RiskScoreScreen({super.key, required this.onStateChanged});

  @override
  // State 클래스의 이름을 public으로 변경하여 GlobalKey가 접근할 수 있도록 합니다.
  RiskScoreScreenState createState() => RiskScoreScreenState();
}

class RiskScoreScreenState extends State<RiskScoreScreen> {
  final BluetoothDeviceService _bluetoothService = BluetoothDeviceService();
  BluetoothDevice? _connectedDevice;
  StreamSubscription<String>? _dataSubscription;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;

  double _pressure = 0.0;
  double _temperature = 0.0;
  double _humidity = 0.0;
  String _backRiskLevel = "정상";
  String _hipRiskLevel = "정상";

  @override
  void dispose() {
    _dataSubscription?.cancel();
    if (_connectedDevice != null && _connectedDevice!.isConnected) {
      _bluetoothService.disconnectFromDevice(_connectedDevice!);
    }
    super.dispose();
  }

  // --- [핵심 2] setState를 호출할 때마다, 부모에게도 알리는 새로운 함수 ---
  // 이 함수는 자신의 UI를 갱신(setState)함과 동시에,
  // 부모 위젯(PatientShell)의 UI(AppBar)도 갱신하라는 신호(widget.onStateChanged())를 보냅니다.
  void _updateState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
      widget.onStateChanged();
    }
  }

  // --- 함수들을 public으로 변경 (앞의 '_' 제거) ---

  void navigateToScanScreen() async {
    if (_connectedDevice != null) {
      await _dataSubscription?.cancel();
      await _bluetoothService.disconnectFromDevice(_connectedDevice!);
      resetSensorData(); // 연결 해제 시 데이터 초기화
      return;
    }

    if (!mounted) return;
    final selectedDevice = await Navigator.of(context).push<BluetoothDevice>(
      MaterialPageRoute(builder: (context) => const BluetoothScanScreen()),
    );

    if (selectedDevice != null) {
      _connectAndListen(selectedDevice);
    }
  }

  void _connectAndListen(BluetoothDevice device) async {
    _updateState(() => _connectionState = BluetoothConnectionState.connecting);

    try {
      await _bluetoothService.connectToDevice(device);
      if (!mounted) return;
      _updateState(() {
        _connectedDevice = device;
        _connectionState = BluetoothConnectionState.connected;
      });

      final dataStream = await _bluetoothService.subscribeToCharacteristic(device);
      _dataSubscription = dataStream.listen(
        _parseData,
        onError: (error) {
          print("데이터 수신 에러: $error");
          if (!mounted) return;
          _updateState(() => _connectionState = BluetoothConnectionState.failed);
        },
        onDone: () {
          print("연결이 끊겼습니다.");
          if (!mounted) return;
          resetSensorData(); // 연결 끊김 시 데이터 초기화
        },
      );
    } catch (e) {
      print("연결 실패: $e");
      if (!mounted) return;
      _updateState(() => _connectionState = BluetoothConnectionState.failed);
    }
  }

  void _parseData(String data) {
    try {
      final parts = data.split(',');
      final pValue = double.parse(parts.firstWhere((p) => p.startsWith('P:')).substring(2));
      final tValue = double.parse(parts.firstWhere((p) => p.startsWith('T:')).substring(2));
      final hValue = double.parse(parts.firstWhere((p) => p.startsWith('H:')).substring(2));

      double backScore = (pValue * 0.08) + (hValue * 0.2);
      String newBackRiskLevel;
      if (backScore > 85) { newBackRiskLevel = "위험"; }
      else if (backScore > 60) { newBackRiskLevel = "주의"; }
      else { newBackRiskLevel = "정상"; }

      _updateState(() {
        _pressure = pValue;
        _temperature = tValue;
        _humidity = hValue;
        _backRiskLevel = newBackRiskLevel;
      });
    } catch (e) {
      print("데이터 파싱 에러: $e, 원본 데이터: $data");
    }
  }

  void resetSensorData() {
    _updateState(() {
      _connectionState = BluetoothConnectionState.disconnected;
      _connectedDevice = null;
      _pressure = 0.0;
      _temperature = 0.0;
      _humidity = 0.0;
      _backRiskLevel = "정상";
      _hipRiskLevel = "정상";
    });
  }

  String getConnectButtonText() {
    switch (_connectionState) {
      case BluetoothConnectionState.disconnected:
      case BluetoothConnectionState.failed:
        return '패드 연결';
      case BluetoothConnectionState.connecting:
        return '연결 중...';
      case BluetoothConnectionState.connected:
        return '연결 해제';
    }
  }

  IconData getConnectIcon() {
    switch (_connectionState) {
      case BluetoothConnectionState.disconnected:
      case BluetoothConnectionState.failed:
        return Icons.bluetooth_disabled;
      case BluetoothConnectionState.connecting:
        return Icons.bluetooth_searching;
      case BluetoothConnectionState.connected:
        return Icons.bluetooth_connected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSensorDataSection(),
          const SizedBox(height: 20),
          Expanded(child: _buildBodyUISection()),
          const SizedBox(height: 20),
          _buildFallRiskSection(),
        ],
      ),
    );
  }

  Widget _buildSensorDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('압력: ${_pressure.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16)),
            Text('온도: ${_temperature.toStringAsFixed(1)} °C', style: const TextStyle(fontSize: 16)),
            Text('습도: ${_humidity.toStringAsFixed(1)} %', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyUISection() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 80, child: _buildRiskIndicator('등', _backRiskLevel)),
          Positioned(top: 150, child: _buildRiskIndicator('엉덩이', _hipRiskLevel)),
        ],
      ),
    );
  }

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
      decoration: BoxDecoration(border: Border.all(color: Colors.orange, width: 2), borderRadius: BorderRadius.circular(8)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('낙상 위험도: 주의 단계', style: TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
