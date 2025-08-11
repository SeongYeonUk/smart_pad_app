import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:smart_pad_app/models/user_model.dart';
import 'package:smart_pad_app/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _restored = false; // 세션 복원 완료 플래그

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _user != null && _token != null;
  bool get isRestored => _restored;

  static const _kTokenKey = 'auth_token';
  static const _kUserKey  = 'auth_user_json';

  /// 앱 시작 시 호출: 저장된 세션 복원 (SharedPreferences 우선, 없으면 SecureStorage에서 마이그레이션)
  Future<void> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? tok = prefs.getString(_kTokenKey);
    String? userJson = prefs.getString(_kUserKey);

    // 1) SP에 세션이 이미 있으면 그대로 복원
    if (tok != null && userJson != null) {
      _applySession(tok, userJson);
      _restored = true;
      notifyListeners();
      return;
    }

    // 2) 예전 방식: SecureStorage에만 저장돼 있던 경우 마이그레이션
    //    (앱이 기존 코드로 loggedInUser만 저장해 왔던 케이스 지원)
    const storage = FlutterSecureStorage();
    final legacyUserJson = await storage.read(key: 'loggedInUser');
    final legacyToken = await storage.read(key: 'auth_token') ?? await storage.read(key: 'token');

    if (legacyUserJson != null && legacyUserJson.isNotEmpty && legacyToken != null && legacyToken.isNotEmpty) {
      // SP로 영구 저장 (이후부터는 SP만 사용)
      await prefs.setString(_kTokenKey, legacyToken);
      await prefs.setString(_kUserKey, legacyUserJson);

      // 메모리에 반영 + ApiService에 주입
      _applySession(legacyToken, legacyUserJson);

      // (선택) 마이그레이션 후 SecureStorage 정리
      await storage.delete(key: 'loggedInUser');
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'token');

      _restored = true;
      notifyListeners();
      return;
    }

    // 3) 여기까지 왔다면 저장된 세션 없음
    _user = null;
    _token = null;
    ApiService.clearToken();
    _restored = true;
    notifyListeners();
  }

  /// 로그인 (반드시 이 경로로 로그인시키면 세션 저장이 보장됨)
  Future<void> login(String username, String password) async {
    final data = await ApiService.login(username, password); // token + user
    final tok = data['token'] as String?;
    if (tok == null) throw Exception('토큰이 누락되었습니다.');

    final u = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await setSession(tok, u);
  }

  /// 외부에서 토큰+유저를 한 번에 설정/저장하고 싶을 때 사용
  Future<void> setSession(String token, UserModel user) async {
    _token = token;
    _user = user;
    ApiService.setToken(token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
    await prefs.setString(_kUserKey, jsonEncode(user.toJson()));

    notifyListeners();
  }

  /// 프로필 이름 변경 등 앱 내에서 유저만 갱신
  Future<void> setUser(UserModel user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    ApiService.clearToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    await prefs.remove(_kUserKey);

    // 예전 SecureStorage 흔적이 남아있다면 함께 제거
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'loggedInUser');
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'token');

    notifyListeners();
  }

  // ===== 내부 유틸 =====

  void _applySession(String token, String userJson) {
    _token = token;
    ApiService.setToken(token);
    try {
      _user = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      _user = null;
      _token = null;
      ApiService.clearToken();
    }
  }
}
