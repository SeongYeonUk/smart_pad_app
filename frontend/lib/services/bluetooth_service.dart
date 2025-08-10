import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// ESP32 펌웨어 코드에 정의된 커스텀 UUID와 반드시 동일해야 합니다.
const String serviceUuidString = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String characteristicUuidString = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

/**
 * 블루투스 통신과 관련된 모든 로직을 캡슐화하는 서비스 클래스.
 * 스캔, 연결, 데이터 수신 등의 기능을 담당합니다.
 */
class BluetoothDeviceService {

  /**
   * 주변 블루투스 기기 스캔 결과 스트림.
   * StreamBuilder와 함께 사용하여 UI에 스캔된 기기 목록을 실시간으로 보여줄 수 있습니다.
   */
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  /**
   * 주변 블루투스 기기 스캔을 시작하는 함수.
   */
  Future<void> startScan() async {
    // 지정된 시간(5초) 동안 스캔을 진행하고 자동으로 중지합니다.
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  /**
   * 진행 중인 스캔을 중지하는 함수.
   */
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /**
   * 특정 블루투스 기기에 연결하는 함수.
   * @param device 연결할 BluetoothDevice 객체.
   */
  Future<void> connectToDevice(BluetoothDevice device) async {
    // 무한정 기다리는 것을 방지하기 위해 15초의 연결 시간 제한을 설정합니다.
    await device.connect(timeout: const Duration(seconds: 15));
  }

  /**
   * 연결된 기기와의 연결을 끊는 함수.
   * @param device 연결을 끊을 BluetoothDevice 객체.
   */
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    await device.disconnect();
  }

  /**
   * 연결된 기기의 특정 Characteristic으로부터 데이터 수신을 시작(구독)하는 함수.
   * @param device 데이터 수신을 시작할 BluetoothDevice 객체.
   * @return String 형태의 데이터가 흘러나오는 Stream.
   */
  Future<Stream<String>> subscribeToCharacteristic(BluetoothDevice device) async {
    // 1. 기기가 제공하는 모든 서비스와 Characteristic들을 검색합니다.
    List<BluetoothService> services = await device.discoverServices();

    // 2. 검색된 서비스들 중에서, 우리가 찾는 서비스 UUID와 일치하는 '서비스'를 찾습니다.
    //    firstWhere는 조건에 맞는 첫 번째 요소를 찾아줍니다.
    //    orElse는 조건에 맞는 요소가 없을 때 null 대신 실행될 함수를 지정하여 에러를 방지합니다.
    var targetService = services.firstWhere(
          (s) => s.serviceUuid == Guid(serviceUuidString),
      orElse: () => throw Exception('원하는 서비스를 찾을 수 없습니다.'),
    );

    // 3. 찾은 서비스 안에서, 우리가 찾는 Characteristic UUID와 일치하는 '통로(Characteristic)'를 찾습니다.
    var targetCharacteristic = targetService.characteristics.firstWhere(
          (c) => c.characteristicUuid == Guid(characteristicUuidString),
      orElse: () => throw Exception('원하는 특성을 찾을 수 없습니다.'),
    );

    // 4. 해당 통로의 'notify' 기능을 활성화합니다.
    //    이것이 활성화되어야 ESP32에서 데이터가 변경될 때마다 앱으로 데이터가 전송됩니다.
    await targetCharacteristic.setNotifyValue(true);

    // 5. onValueReceived 스트림은 List<int> (바이트 배열) 형태의 데이터를 받습니다.
    //    map() 함수를 사용하여 이 데이터를 우리가 읽을 수 있는 String(문자열) 형태로 변환한
    //    새로운 스트림을 만들어서 반환합니다.
    return targetCharacteristic.onValueReceived.map((value) {
      if (value.isEmpty) {
        return ""; // 가끔 빈 데이터가 올 경우를 대비한 예외 처리
      }
      return utf8.decode(value); // 받은 데이터를 UTF-8 형식의 문자열로 변환하여 반환
    });
  }
}
