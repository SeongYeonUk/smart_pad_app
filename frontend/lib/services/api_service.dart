import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_pad_app/models/user_model.dart';

class ApiService {
  // ❗️ 실제 기기에서 테스트 시, ipconfig로 찾은 PC의 IPv4 주소를 사용해야 합니다.
  static const String _baseUrl = 'http://192.168.0.108:8080';
  // ❗️ 에뮬레이터에서 테스트 시에는 'http://10.0.2.2:8080'를 사용하세요.

  // --- 회원가입 API 호출 함수 ---
  static Future<void> signup(Map<String, dynamic> userData) async {
    final url = Uri.parse('$_baseUrl/api/auth/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        // 서버가 에러 메시지를 보냈을 경우, 해당 메시지를 Exception에 담아 전달
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['message'] ?? '회원가입에 실패했습니다.');
      }
      print('ApiService: 회원가입 성공!');

    } catch (e) {
      // 네트워크 에러 또는 위에서 던진 Exception을 다시 던짐
      print('ApiService: 회원가입 에러: $e');
      throw Exception('서버와 통신 중 오류가 발생했습니다.');
    }
  }

  // --- 로그인 API 호출 함수 ---
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return responseData; // {'token': '...', 'user': {...}} 형태의 Map을 그대로 반환
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['message'] ?? '아이디 또는 비밀번호가 일치하지 않습니다.');
      }
    } catch (e) {
      print('ApiService: 로그인 에러: $e');
      throw Exception('서버와 통신 중 오류가 발생했습니다.');
    }
  }

  // --- ▼▼▼ [핵심] 회원 탈퇴 API 호출 함수 추가 ▼▼▼ ---

  /**
   * 회원 탈퇴 API 호출 함수
   * @param username 탈퇴할 사용자의 아이디
   */
  static Future<void> deleteUser(String username) async {
    // TODO: 실제 서비스에서는 JWT 토큰을 헤더에 담아 "본인"임을 인증해야 합니다.
    // final token = await storage.read(key: 'jwtToken');
    // final headers = {
    //   'Content-Type': 'application/json',
    //   'Authorization': 'Bearer $token'
    // };

    // DELETE /api/auth/delete/{username} 형태의 URL을 생성합니다.
    final url = Uri.parse('$_baseUrl/api/auth/delete/$username');

    try {
      // DELETE HTTP 메서드로 서버에 요청을 보냅니다.
      final response = await http.delete(url);

      // 성공(200 OK) 응답이 아니면 에러를 발생시킵니다.
      if (response.statusCode != 200) {
        throw Exception('회원 탈퇴 처리 중 서버에서 오류가 발생했습니다.');
      }

      // 성공 시에는 아무것도 반환하지 않습니다.
      print('ApiService: 회원 탈퇴 성공!');

    } catch (e) {
      print('ApiService: 회원 탈퇴 에러: $e');
      throw Exception('서버와 통신 중 오류가 발생했습니다.');
    }
  }
}
