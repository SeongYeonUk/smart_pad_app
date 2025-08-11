// PatientDetailModel.dart 파일 (기존 파일)

import 'package:smart_pad_app/models/user_model.dart';

// 나이대를 상수(const)로 정의하여 오타를 방지하고 코드의 일관성을 유지합니다.
class AgeRanges {
  static const String age1_20 = '1~20살';
  static const String age21_40 = '21~40살';
  static const String age41_60 = '41~60살';
  static const String age61_80 = '61~80살';
  static const String age81_plus = '81살 이상';

  // ▼▼▼ 여기에 모든 연령대 목록을 담는 리스트를 추가합니다. ▼▼▼
  static const List<String> allRanges = [
    age1_20,
    age21_40,
    age41_60,
    age61_80,
    age81_plus,
  ];
}

class PatientDetailModel {
  final int patientId;
  final double weight;

  // 나이를 정수(int) 대신 문자열(String)로 변경
  final String ageRange;

  final String sensoryPerception;
  final String activityLevel;
  final String movementLevel;

  PatientDetailModel({
    required this.patientId,
    required this.weight,
    required this.ageRange, // 매개변수 이름을 age에서 ageRange로 변경
    required this.sensoryPerception,
    required this.activityLevel,
    required this.movementLevel,
  });

  factory PatientDetailModel.fromJson(Map<String, dynamic> json) {
    return PatientDetailModel(
      patientId: json['patientId'],
      weight: json['weight'].toDouble(),
      ageRange: json['ageRange'], // JSON 키를 age에서 ageRange로 변경
      sensoryPerception: json['sensoryPerception'],
      activityLevel: json['activityLevel'],
      movementLevel: json['movementLevel'],
    );
  }
}

class Patient {
  final UserModel user;
  final PatientDetailModel? detail;

  Patient({required this.user, this.detail});
}
