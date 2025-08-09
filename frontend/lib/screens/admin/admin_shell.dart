import 'package:flutter/material.dart';
// 관리자용 탭에 필요한 화면들을 import 합니다.
// 'frontend'를 프로젝트 이름으로 사용하고 있으므로, 경로를 수정합니다.
import 'package:smart_pad_app/screens/admin/patient_list_screen.dart';
import 'package:smart_pad_app/screens/common/notification_screen.dart';
import 'package:smart_pad_app/screens/common/settings_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0; // 현재 선택된 탭의 인덱스

  // 관리자용 하단 탭에 연결될 페이지 위젯 목록
  static const List<Widget> _widgetOptions = <Widget>[
    PatientListScreen(),   // 0번: 환자 목록
    NotificationScreen(),  // 1번: 알림
    SettingsScreen(),      // 2번: 설정
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body는 선택된 인덱스에 맞는 페이지를 보여줌
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people_alt),
            label: '환자 목록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: '알림',
          ), //  <--- 여기에 쉼표(,)를 추가했습니다!
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
    );
  }
}

