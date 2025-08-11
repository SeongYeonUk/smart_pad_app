import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_pad_app/models/diet_log_model.dart';

class ApiService {
  // ❗ 실기기: PC의 IPv4로 변경 / 에뮬레이터: http://10.0.2.2:8080
  static const String _baseUrl = 'http://10.210.96.165:8080';

  // ===== JWT 토큰 관리 =====
  static String? _jwt;
  static void setToken(String token) => _jwt = token;
  static void clearToken() => _jwt = null;
  static String? get token => _jwt;

  static Map<String, String> _headersJson() => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_jwt != null) 'Authorization': 'Bearer $_jwt',
  };

  // ===== 공통 처리 =====
  static const Duration _timeout = Duration(seconds: 15);

  static T _decodeJson<T>(List<int> bodyBytes) {
    final s = utf8.decode(bodyBytes);
    final obj = jsonDecode(s);
    return obj as T;
  }

  static Map<String, dynamic>? _tryDecodeMap(List<int> bodyBytes) {
    try {
      final v = _decodeJson<dynamic>(bodyBytes);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }

  static Never _throwHttp(String fallback, http.Response res) {
    final err = _tryDecodeMap(res.bodyBytes);
    throw HttpException(err?['message']?.toString() ?? '$fallback [${res.statusCode}]');
  }

  // ===== Auth =====
  static Future<void> signup(Map<String, dynamic> userData) async {
    final url = Uri.parse('$_baseUrl/api/auth/signup');
    try {
      final res = await http
          .post(url, headers: _headersJson(), body: jsonEncode(userData))
          .timeout(_timeout);
      if (res.statusCode != 200 && res.statusCode != 201) {
        _throwHttp('회원가입에 실패했습니다.', res);
      }
    } on SocketException {
      throw const HttpException('네트워크에 연결할 수 없습니다.');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException('회원가입 처리 중 오류가 발생했습니다: $e');
    }
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');
    try {
      final res = await http
          .post(
        url,
        headers: _headersJson(),
        body: jsonEncode({'username': username, 'password': password}),
      )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final data = _decodeJson<Map<String, dynamic>>(res.bodyBytes);
        final tk = data['token'] as String?;
        if (tk != null) setToken(tk);
        return data;
      }
      _throwHttp('아이디 또는 비밀번호가 일치하지 않습니다.', res);
    } on SocketException {
      throw const HttpException('네트워크에 연결할 수 없습니다.');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException('로그인 처리 중 오류가 발생했습니다: $e');
    }
  }

  static Future<void> deleteUser(String username) async {
    final url = Uri.parse('$_baseUrl/api/auth/delete/$username');
    try {
      final res = await http.delete(url, headers: _headersJson()).timeout(_timeout);
      if (res.statusCode != 200) {
        _throwHttp('회원 탈퇴 처리 중 서버 오류가 발생했습니다.', res);
      }
    } on SocketException {
      throw const HttpException('네트워크에 연결할 수 없습니다.');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException('회원 탈퇴 처리 중 오류가 발생했습니다: $e');
    }
  }

  // ===== Profile =====
  static Future<Map<String, dynamic>> fetchPatientDetail(int userId) async {
    final url = Uri.parse('$_baseUrl/api/patient_detail/$userId');
    try {
      final res = await http.get(url, headers: _headersJson()).timeout(_timeout);
      if (res.statusCode == 200) {
        return _decodeJson<Map<String, dynamic>>(res.bodyBytes);
      }
      if (res.statusCode == 404) return {};
      if (res.statusCode == 401 || res.statusCode == 403) {
        _throwHttp('인증이 필요합니다. 다시 로그인 해주세요.', res);
      }
      _throwHttp('환자 정보를 불러오는 데 실패했습니다.', res);
    } on SocketException {
      throw const HttpException('네트워크에 연결할 수 없습니다.');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException('환자 정보 조회 중 오류가 발생했습니다: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchAdminDetail(int userId) async {
    final url = Uri.parse('$_baseUrl/api/admin_detail/$userId');
    try {
      final res = await http.get(url, headers: _headersJson()).timeout(_timeout);
      if (res.statusCode == 200) {
        return _decodeJson<Map<String, dynamic>>(res.bodyBytes);
      }
      if (res.statusCode == 404) return {};
      if (res.statusCode == 401 || res.statusCode == 403) {
        _throwHttp('인증이 필요합니다. 다시 로그인 해주세요.', res);
      }
      _throwHttp('관리자 정보를 불러오는 데 실패했습니다.', res);
    } on SocketException {
      throw const HttpException('네트워크에 연결할 수 없습니다.');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException('관리자 정보 조회 중 오류가 발생했습니다: $e');
    }
  }

  static Future<void> updateProfile(int userId, Map<String, dynamic> updateData) async {
    final url = Uri.parse('$_baseUrl/api/users/$userId');
    try {
      final res = await http
          .put(url, headers: _headersJson(), body: jsonEncode(updateData))
          .timeout(_timeout);
      if (res.statusCode != 200) {
        _throwHttp('프로필 업데이트에 실패했습니다.', res);
      }
    } on SocketException {
      throw const HttpException('네트워크에 연결할 수 없습니다.');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException('프로필 업데이트 중 오류가 발생했습니다: $e');
    }
  }

  // ===== Diet =====
  static Future<DietLogModel> saveDietLog(int userId, Map<String, dynamic> dietData) async {
    final url = Uri.parse('$_baseUrl/api/diet/$userId');
    try {
      final res = await http
          .post(url, headers: _headersJson(), body: jsonEncode(dietData))
          .timeout(_timeout);

      // 201(권장) 또는 200(허용) 또는 204(빈 본문)까지 대응
      if (res.statusCode == 201 || res.statusCode == 200) {
        if (res.bodyBytes.isNotEmpty) {
          final obj = _decodeJson<dynamic>(res.bodyBytes);
          if (obj is Map<String, dynamic>) {
            return DietLogModel.fromJson(obj);
          }
        }
        // 서버가 본문을 안 보낸 경우, 방금 전송한 데이터로라도 구성
        return DietLogModel.fromJson(dietData);
      }
      if (res.statusCode == 204) {
        return DietLogModel.fromJson(dietData);
      }

      _throwHttp('식단 기록 저장에 실패했습니다.', res);
    } on SocketException {
      throw const HttpException('네트워크에 연결할 수 없습니다.');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException('식단 기록 저장 중 오류가 발생했습니다: $e');
    }
  }

  static Future<List<DietLogModel>> getDietLogs(int userId) async {
    final url = Uri.parse('$_baseUrl/api/diet/$userId');
    try {
      final res = await http.get(url, headers: _headersJson()).timeout(_timeout);
      if (res.statusCode == 200) {
        final obj = _decodeJson<dynamic>(res.bodyBytes);
        if (obj is List) {
          return obj
              .whereType<Map<String, dynamic>>()
              .map((j) => DietLogModel.fromJson(j))
              .toList();
        }
        return const [];
      }
      if (res.statusCode == 401 || res.statusCode == 403) {
        _throwHttp('인증이 필요합니다. 다시 로그인 해주세요.', res);
      }
      _throwHttp('식단 기록을 불러오는 데 실패했습니다.', res);
    } on SocketException {
      throw const HttpException('네트워크에 연결할 수 없습니다.');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException('식단 기록 조회 중 오류가 발생했습니다: $e');
    }
  }
}
