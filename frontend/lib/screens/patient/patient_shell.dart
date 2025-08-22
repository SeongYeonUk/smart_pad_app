import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // ✅ 추가
import 'package:smart_pad_app/providers/auth_provider.dart'; // ✅ 추가

import 'package:smart_pad_app/screens/common/notification_screen.dart';
import 'package:smart_pad_app/screens/common/settings_screen.dart';
import 'package:smart_pad_app/screens/patient/diet_info_screen.dart';
import 'package:smart_pad_app/screens/patient/risk_score_screen.dart';

// NotificationScreen은 State 클래스 이름이 NotificationScreenState 라고 가정합니다.
// 만약 다르면 아래 GlobalKey의 제네릭과 호출부의 메서드명을 맞춰주세요.

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _selectedIndex = 0;

  // 자식 화면 제어용 GlobalKey
  final GlobalKey<RiskScoreScreenState> _riskKey = GlobalKey<RiskScoreScreenState>();
  final GlobalKey<NotificationScreenState> _notiKey = GlobalKey<NotificationScreenState>();

  // AppBar 제목
  final List<String> _appBarTitles = const ['욕창 위험도', '알림창', '식생활 정보', '설정'];

  // 페이지 목록 (키를 부여해서 상단 AppBar actions에서 제어)
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      RiskScoreScreen(key: _riskKey),
      NotificationScreen(key: _notiKey),
      const DietInfoScreen(),
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  List<Widget> _buildActions() {
    // ✅ 원래 조건과 동일: JWT 있을 때만 위험도 새로고침 노출
    final hasToken = context.select<AuthProvider, bool>((a) => a.token != null);

    switch (_selectedIndex) {
      case 0: // 위험도
        return hasToken
            ? [
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: () => _riskKey.currentState?.fetchLatestOncePublic(),
          ),
        ]
            : const [];
      case 1: // 알림: 항상 "모두 읽음" 버튼 표시
        return [
          TextButton(
            onPressed: () => _notiKey.currentState?.markAllAsReadPublic(),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('모두 읽음'),
          ),
        ];
      default:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitles[_selectedIndex]),
          automaticallyImplyLeading: false,
          actions: _buildActions(),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield),
              label: '위험도',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none),
              activeIcon: Icon(Icons.notifications),
              label: '알림',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu),
              label: '식단',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: '설정',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
