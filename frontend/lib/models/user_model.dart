// 사용자의 역할을 구분하기 위한 열거형(enum). 코드의 가독성을 높여줍니다.
enum UserRole { patient, admin }

class UserModel {
  final int id;            // MySQL의 Primary Key (auto_increment, BIGINT 등)
  final String username;     // 로그인 시 사용할 아이디
  final String name;         // 사용자 실명
  final UserRole role;       // 역할 (환자 / 관리자)

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  // (나중에 필요) 서버의 JSON 데이터를 받아서 UserModel 객체로 변환하는 생성자
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      name: json['name'],
      role: (json['role'] as String).toLowerCase() == 'patient'
          ? UserRole.patient
          : UserRole.admin,
    );
  }
}
