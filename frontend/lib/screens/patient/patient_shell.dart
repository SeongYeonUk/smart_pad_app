import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_pad_app/screens/common/notification_screen.dart';
import 'package:smart_pad_app/screens/common/settings_screen.dart';
import 'package:smart_pad_app/screens/patient/diet_info_screen.dart';
import 'package:smart_pad_app/screens/patient/risk_score_screen.dart'; // 기존 risk_score_screen.dart를 사용

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _selectedIndex = 0;

  // AppBar 제목 목록
  final List<String> _appBarTitles = const ['욕창 위험도', '알림', '식생활 정보', '설정'];

  // BottomNavigationBar에 표시할 페이지 위젯 목록
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      // risk_score_screen.dart를 직접 사용
      const RiskScoreScreen(),
      const NotificationScreen(),
      const DietInfoScreen(),
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
          // 블루투스 연결 버튼/아이콘 제거 → actions 없음
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), activeIcon: Icon(Icons.shield), label: '위험도'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_none), activeIcon: Icon(Icons.notifications), label: '알림'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_outlined), activeIcon: Icon(Icons.restaurant_menu), label: '식단'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: '설정'),
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
