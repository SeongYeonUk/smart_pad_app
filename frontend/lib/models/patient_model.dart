import 'package:smart_pad_app/models/user_model.dart'; // UserModel을 가져오기 위함

class PatientDetailModel {
  // 환자의 상세 정보만을 담는 모델
  final int patientId; // 이 상세정보의 고유 ID
  final double weight;
  final int age;
  // Braden Scale과 유사한 척도들을 문자열로 관리
  final String sensoryPerception; // 감각인지 (최상, 상, 중, 하)
  final String activityLevel;     // 활동량
  final String movementLevel;     // 운동량
  // TODO: 여기에 더 필요한 환자 고유 정보들을 추가할 수 있습니다.
  // 예: final String patientCode; // 관리자가 환자를 추가할 때 사용하는 코드

  PatientDetailModel({
    required this.patientId,
    required this.weight,
    required this.age,
    required this.sensoryPerception,
    required this.activityLevel,
    required this.movementLevel,
  });

  // (나중에 필요) JSON 데이터를 PatientDetailModel 객체로 변환
  factory PatientDetailModel.fromJson(Map<String, dynamic> json) {
    return PatientDetailModel(
      patientId: json['patientId'],
      weight: json['weight'].toDouble(),
      age: json['age'],
      sensoryPerception: json['sensoryPerception'],
      activityLevel: json['activityLevel'],
      movementLevel: json['movementLevel'],
    );
  }
}


// 실제 앱에서 사용할 때는 기본 유저 정보와 상세 정보를 합쳐서 사용
class Patient {
  final UserModel user; // 기본 사용자 정보
  final PatientDetailModel? detail; // 상세 정보 (선택적일 수 있음)

  Patient({required this.user, this.detail});
}
