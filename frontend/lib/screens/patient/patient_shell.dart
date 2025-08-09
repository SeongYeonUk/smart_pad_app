import 'package:flutter/material.dart';
// 앞으로 만들 페이지들을 미리 import 합니다.
import 'package:smart_pad_app/screens/common/notification_screen.dart';
import 'package:smart_pad_app/screens/common/settings_screen.dart';
import 'package:smart_pad_app/screens/patient/diet_info_screen.dart';
import 'package:smart_pad_app/screens/patient/risk_score_screen.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _selectedIndex = 0; // 현재 선택된 탭의 인덱스를 저장할 변수

  // 하단 탭에 연결될 페이지 위젯 목록
  static const List<Widget> _widgetOptions = <Widget>[
    RiskScoreScreen(),     // 0번: 위험도
    NotificationScreen(),  // 1번: 알림
    DietInfoScreen(),      // 2번: 식단
    SettingsScreen(),      // 3번: 설정
  ];

  // 탭이 눌렸을 때 호출될 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // 탭 인덱스를 변경하고 화면을 다시 그리도록 요청
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // 선택된 인덱스에 맞는 페이지를 화면 중앙에 보여줌
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield), // 선택됐을 때 아이콘
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
        selectedItemColor: Theme.of(context).primaryColor, // 선택된 아이템 색상
        unselectedItemColor: Colors.grey, // 선택되지 않은 아이템 색상
        onTap: _onItemTapped,
        showUnselectedLabels: true, // 선택되지 않은 라벨도 항상 보이게 설정
        type: BottomNavigationBarType.fixed, // 탭이 많아도 고정된 크기 유지
      ),
    );
  }
}
