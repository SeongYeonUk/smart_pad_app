import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemNavigator.pop()을 사용하기 위해 import 합니다.

// 관리자용 탭에 필요한 화면들을 import 합니다.
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
  // IndexedStack을 사용하므로, 상태 유지를 위해 const를 제거합니다.
  final List<Widget> _widgetOptions = <Widget>[
    const PatientListScreen(),   // 0번: 환자 목록
    const NotificationScreen(),  // 1번: 알림
    const SettingsScreen(),      // 2번: 설정
  ];

  // 탭이 눌렸을 때 호출될 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- [핵심] WillPopScope 위젯으로 Scaffold를 감싸줍니다. ---
    // 이 위젯은 사용자의 '뒤로 가기' 액션을 감지하고 제어하는 역할을 합니다.
    return WillPopScope(
      // onWillPop 콜백은 사용자가 뒤로가기를 시도할 때마다 호출됩니다.
      onWillPop: () async {
        // 뒤로가기를 누르면 앱을 완전히 종료시키도록 명령합니다.
        SystemNavigator.pop();

        // 뒤로가기 액션 자체는 무시하도록 false를 반환합니다.
        return false;
      },
      child: Scaffold(
        // IndexedStack을 사용하여 탭 간 상태를 유지합니다.
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
