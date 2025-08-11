// 사용자의 역할 구분
enum UserRole { patient, admin }

// 서버/앱 간 문자열 변환 헬퍼
UserRole roleFromString(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'PATIENT':
      return UserRole.patient;
    case 'ADMIN':
      return UserRole.admin;
    default:
      return UserRole.patient; // 기본값
  }
}

String roleToString(UserRole role) {
  switch (role) {
    case UserRole.patient:
      return 'PATIENT';
    case UserRole.admin:
      return 'ADMIN';
  }
}

class UserModel {
  final int id;         // PK
  final String username;
  final String name;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // id가 num/int/strings 모두 안전 캐스팅
    final rawId = json['id'];
    final id = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return UserModel(
      id: id,
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: roleFromString(json['role']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name': name,
    'role': roleToString(role), // 서버 enum과 호환 (PATIENT/ADMIN)
  };

  UserModel copyWith({
    int? id,
    String? username,
    String? name,
    UserRole? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }
}
