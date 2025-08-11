import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_pad_app/providers/auth_provider.dart';
import 'package:smart_pad_app/models/user_model.dart';
import 'package:smart_pad_app/services/api_service.dart';
import 'package:smart_pad_app/screens/auth/edit_profile_screen.dart'; // ← 경로 수정

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (authProvider.isLoggedIn && user != null)
            UserAccountsDrawerHeader(
              accountName: Text(
                user.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text('아이디: ${user.username}'),
              currentAccountPicture: CircleAvatar(
                child: Text(
                  // 이니셜 안전 처리
                  (user.name.isNotEmpty ? user.name.substring(0, 1) : '?'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),

          const SizedBox(height: 10),

          _buildSectionTitle(context, '개인 정보'),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('개인정보 변경'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (user != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
                );
              }
            },
          ),
          const Divider(),

          _buildSectionTitle(context, '계정 관리'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () => _showLogoutDialog(context),
          ),
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

          _buildSectionTitle(context, '앱 정보'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('앱 버전'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

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
            onPressed: () async {
              // ✅ AuthProvider에서 토큰/유저/저장소 정리까지 수행
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/start', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

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
            onPressed: () async {
              try {
                await ApiService.deleteUser(username);
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('회원 탈퇴가 성공적으로 처리되었습니다.')),
                  );
                }
                // ✅ 탈퇴 후 세션 정리 및 시작 화면 이동
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/start', (route) => false);
                }
              } catch (e) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('탈퇴 처리 중 오류 발생: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
