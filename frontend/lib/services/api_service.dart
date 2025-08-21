import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_pad_app/models/diet_log_model.dart';

class ApiService {
  // ❗ 실기기: 서버의 공인IP/사설IP로 변경
  //  - 에뮬레이터(AVD): http://10.0.2.2:8080
  //  - 실기기와 서버가 서로 다른 와이파이여도, 서버가 외부에서 접근 가능(포트포워딩/공인IP/도메인)하면 연결 가능
  static const String _baseUrl = 'http://192.168.0.107:8080'; // TODO: 환경에 맞게 수정

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
    final bool isUpdate = dietData.containsKey('id');
    final String path = isUpdate ? '/api/diet/${dietData['id']}' : '/api/diet/$userId';
    final url = Uri.parse('$_baseUrl$path');

    try {
      final res = isUpdate
          ? await http.put(url, headers: _headersJson(), body: jsonEncode(dietData)).timeout(_timeout)
          : await http.post(url, headers: _headersJson(), body: jsonEncode(dietData)).timeout(_timeout);

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (res.bodyBytes.isNotEmpty) {
          final obj = _decodeJson<dynamic>(res.bodyBytes);
          if (obj is Map<String, dynamic>) {
            return DietLogModel.fromJson(obj);
          }
        }
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

  static Future<void> deleteDietLog(int logId) async {
    final url = Uri.parse('$_baseUrl/api/diet/$logId');
    try {
      final res = await http.delete(url, headers: _headersJson()).timeout(_timeout);
      if (res.statusCode != 200) {
        _throwHttp('식단 기록 삭제에 실패했습니다.', res);
      }
    } on SocketException {
      throw const HttpException('네트워크에 연결할 수 없습니다.');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException('식단 기록 삭제 중 오류가 발생했습니다: $e');
    }
  }

  // ==========================
  // ===== Sensors (NEW) ======
  // ==========================

  /// 로그인한 사용자(현재 JWT)의 환자 레코드에 센서 데이터 1건 저장
  /// - 서버가 SecurityContext로 사용자→환자를 찾아 자동 매핑
  static Future<void> postSensorReading({
    required int pressure,
    required int temperature,
    required int humidity,
    DateTime? timestamp, // 서버에서 now 처리하므로 선택
  }) async {
    final url = Uri.parse('$_baseUrl/api/sensor-data');
    final body = {
      'pressure': pressure,
      'temperature': temperature,
      'humidity': humidity,
      if (timestamp != null) 'timestamp': timestamp.toIso8601String(), // 컨트롤러에서 무시한다면 제거해도 OK
    };

    try {
      final res = await http
          .post(url, headers: _headersJson(), body: jsonEncode(body))
          .timeout(_timeout);

      if (res.statusCode != 200 && res.statusCode != 201) {
        _throwHttp('센서 데이터 저장에 실패했습니다.', res);
      }
    } on SocketException {
      throw const HttpException('네트워크에 연결할 수 없습니다.');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException('센서 데이터 저장 중 오류가 발생했습니다: $e');
    }
  }

  /// 로그인한 사용자의 환자 최신 센서 데이터 목록
  /// - limit=1 이면 가장 최근 한 건만
  static Future<List<Map<String, dynamic>>> fetchLatestReadings({int limit = 1}) async {
    final url = Uri.parse('$_baseUrl/api/sensor-data/latest?limit=$limit');

    try {
      final res = await http.get(url, headers: _headersJson()).timeout(_timeout);
      if (res.statusCode == 200) {
        final obj = _decodeJson<dynamic>(res.bodyBytes);
        if (obj is List) {
          return obj.whereType<Map<String, dynamic>>().toList();
        }
        return const [];
      }
      _throwHttp('센서 데이터 조회에 실패했습니다.', res);
    } on SocketException {
      throw const HttpException('네트워크에 연결할 수 없습니다.');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException('센서 데이터 조회 중 오류가 발생했습니다: $e');
    }
  }
}
