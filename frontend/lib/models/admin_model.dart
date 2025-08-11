// lib/models/admin_model.dart

class AdminModel {
  final String hospitalName;

  AdminModel({
    required this.hospitalName,
  });

  // Flutter 앱에서 서버로 보낼 JSON 데이터를 만드는 메서드
  Map<String, dynamic> toJson() {
    return {
      'hospitalName': hospitalName,
    };
  }
}