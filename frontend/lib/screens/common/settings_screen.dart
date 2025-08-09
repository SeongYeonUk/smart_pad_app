import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Secure Storage를 사용하기 위해 import 합니다.
import 'package:provider/provider.dart';
import 'package:smart_pad_app/providers/auth_provider.dart';
import 'package:smart_pad_app/models/user_model.dart';
import 'package:smart_pad_app/services/api_service.dart'; // ApiService를 사용하기 위해 import 합니다.

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // build 함수 내에서 Provider를 통해 AuthProvider의 인스턴스를 가져옵니다.
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user; // 현재 로그인한 사용자 정보

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        automaticallyImplyLeading: false, // AppBar의 뒤로가기 버튼 숨기기
      ),
      body: ListView(
        padding: EdgeInsets.zero, // ListView 상단의 불필요한 여백 제거
        children: [
          // 1. 사용자 프로필 섹션: 로그인한 경우에만 보임
          if (authProvider.isLoggedIn && user != null)
            UserAccountsDrawerHeader(
              accountName: Text(
                user.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text('아이디: ${user.username}'),
              currentAccountPicture: CircleAvatar(
                child: Text(
                  user.name.substring(0, 1),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),

          const SizedBox(height: 10),

          // 2. 역할별 메뉴 섹션
          if (user?.role == UserRole.patient) ...[
            _buildSectionTitle(context, '개인 정보'),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('개인정보 변경'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () { /* TODO: 개인정보 변경 화면으로 이동 */ },
            ),
            const Divider(),
          ],

          if (user?.role == UserRole.admin) ...[
            _buildSectionTitle(context, '관리자 설정'),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('관리자용 설정'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () { /* TODO: 관리자용 설정 화면으로 이동 */ },
            ),
            const Divider(),
          ],

          // 3. 계정 관리 섹션
          _buildSectionTitle(context, '계정 관리'),
          // 로그아웃 메뉴
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
          // 회원 탈퇴 메뉴
          ListTile(
            leading: Icon(Icons.person_remove_outlined, color: Colors.red.shade700),
            title: Text('회원 탈퇴', style: TextStyle(color: Colors.red.shade700)),
            onTap: () {
              if (user != null) {
                _showDeleteUserDialog(context, user.username);
              }
            },
          ),
          const Divider(),

          // 4. 앱 정보 섹션
          _buildSectionTitle(context, '앱 정보'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('앱 버전'),
            subtitle: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  // 섹션 제목을 위한 작은 위젯
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  // --- 다이얼로그 함수들 ---

  // 로그아웃 확인 다이얼로그
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말로 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
            onPressed: () async { // async 키워드 추가
              // --- [핵심] 저장된 로그인 정보 삭제 ---
              const storage = FlutterSecureStorage();
              await storage.delete(key: 'loggedInUser');
              // TODO: JWT 토큰도 함께 삭제 await storage.delete(key: 'jwtToken');

              // Provider 상태 초기화
              Provider.of<AuthProvider>(context, listen: false).clearUser();

              // 시작 화면으로 이동
              Navigator.of(context).pushNamedAndRemoveUntil('/start', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  // 회원 탈퇴 확인 다이얼로그
  void _showDeleteUserDialog(BuildContext context, String username) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('회원 탈퇴', style: TextStyle(color: Colors.red)),
        content: const Text('정말로 탈퇴하시겠습니까?\n모든 정보가 영구적으로 삭제되며, 복구할 수 없습니다.'),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: const Text('탈퇴하기', style: TextStyle(color: Colors.red)),
            onPressed: () async { // async 키워드 추가
              try {
                // 1. ApiService를 통해 실제 회원 탈퇴 요청
                await ApiService.deleteUser(username);

                // 2. Secure Storage에 저장된 정보 삭제
                const storage = FlutterSecureStorage();
                await storage.delete(key: 'loggedInUser');
                // TODO: JWT 토큰도 함께 삭제

                // 3. Provider 상태 초기화 (로그아웃 처리)
                Provider.of<AuthProvider>(context, listen: false).clearUser();

                // 4. 시작 화면으로 이동
                Navigator.of(context).pushNamedAndRemoveUntil('/start', (route) => false);

              } catch (e) {
                // 에러 발생 시
                Navigator.of(dialogContext).pop(); // 일단 다이얼로그 닫기
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('탈퇴 처리 중 오류 발생: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
