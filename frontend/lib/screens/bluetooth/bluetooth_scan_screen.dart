import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:smart_pad_app/services/bluetooth_service.dart';
import 'package:permission_handler/permission_handler.dart'; // [핵심] permission_handler import

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  final BluetoothDeviceService _bluetoothService = BluetoothDeviceService();
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    // 화면이 시작되자마자, 권한을 먼저 요청하고 그 다음에 스캔을 시작합니다.
    _requestPermissionsAndStartScan();
  }

  // --- ▼▼▼ [핵심] 이 함수를 통째로 추가하세요! ▼▼▼ ---
  Future<void> _requestPermissionsAndStartScan() async {
    print("권한 요청을 시작합니다...");

    // 안드로이드에서 BLE 스캔에 필요한 권한 목록
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,        // 위치 정보 (필수)
      Permission.bluetoothScan,   // 블루투스 스캔 (필수)
      Permission.bluetoothConnect,  // 블루투스 연결 (필수)
    ].request();

    // 모든 권한이 허용되었는지 확인
    if (statuses[Permission.location]!.isGranted &&
        statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted) {
      print("모든 블루투스 권한이 허용되었습니다. 스캔을 시작합니다.");
      _startScan();
    } else {
      print("하나 이상의 필수 블루투스 권한이 거부되었습니다.");
      // 사용자에게 권한이 왜 필요한지 설명하는 팝업을 띄우는 것이 좋습니다.
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('블루투스 스캔을 위해 권한을 허용해주세요. 앱 설정에서 변경할 수 있습니다.')),
        );
      }
    }
  }
  // --- ▲▲▲ 여기까지 추가 ▲▲▲ ---

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  void _startScan() {
    if (_isScanning) return;
    setState(() => _isScanning = true);
    _scanSubscription = _bluetoothService.scanResults.listen((results) {
      setState(() => _scanResults = results);
    });
    _bluetoothService.startScan();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _stopScan();
    });
  }

  void _stopScan() {
    _bluetoothService.stopScan();
    _scanSubscription?.cancel();
    if (mounted) setState(() => _isScanning = false);
  }

  void _connectToDevice(BluetoothDevice device) {
    _stopScan();
    Navigator.of(context).pop(device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스마트 패드 찾기'),
      ),
      body: ListView.builder(
        itemCount: _scanResults.length,
        itemBuilder: (context, index) {
          final result = _scanResults[index];
          final deviceName = result.device.platformName.isNotEmpty
              ? result.device.platformName
              : "Unknown Device";

          return ListTile(
            title: Text(deviceName),
            subtitle: Text(result.device.remoteId.toString()),
            leading: const Icon(Icons.bluetooth_searching),
            trailing: Text('${result.rssi} dBm'),
            onTap: () => _connectToDevice(result.device),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _requestPermissionsAndStartScan, // 새로고침 버튼도 권한 확인부터
        backgroundColor: _isScanning ? Colors.grey : Theme.of(context).primaryColor,
        child: _isScanning
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.replay, color: Colors.white),
      ),
    );
  }
}
