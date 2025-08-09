import 'package:flutter/material.dart';
// Provider와 AuthProvider, UserModel을 사용하기 위해 import 합니다.
import 'package:provider/provider.dart';
import 'package:smart_pad_app/providers/auth_provider.dart';
import 'package:smart_pad_app/models/user_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // build 함수 안에서 Provider를 통해 AuthProvider의 인스턴스를 가져옵니다.
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

          // 3. 공통 메뉴 섹션
          _buildSectionTitle(context, '앱'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () {
              // --- [핵심 수정] 별도의 함수 대신, onTap 콜백 안에서 직접 showDialog를 호출 ---
              showDialog(
                context: context, // 여기서 사용된 context는 SettingsScreen의 유효한 context
                builder: (dialogContext) => AlertDialog( // builder는 다이얼로그를 위한 새로운 context를 제공
                  title: const Text('로그아웃'),
                  content: const Text('정말로 로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      child: const Text('취소'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // 다이얼로그를 닫을 땐 다이얼로그의 context 사용
                      },
                    ),
                    TextButton(
                      child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        // Provider와 Navigator는 앱 전체에서 사용 가능하므로, 바깥 context를 사용해도 안전
                        Provider.of<AuthProvider>(context, listen: false).clearUser();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/start',
                              (Route<dynamic> route) => false,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
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
  // context를 인자로 받도록 수정하여 Theme에 안전하게 접근
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
}
