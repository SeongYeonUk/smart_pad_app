import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemNavigator.pop()을 사용하기 위해 import 합니다.

// 페이지 위젯들을 import 합니다.
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
  // IndexedStack을 사용하므로, 상태 유지를 위해 const를 제거합니다.
  final List<Widget> _widgetOptions = <Widget>[
    const RiskScoreScreen(),     // 0번: 위험도
    const NotificationScreen(),  // 1번: 알림
    const DietInfoScreen(),      // 2번: 식단
    const SettingsScreen(),      // 3번: 설정
  ];

  // 탭이 눌렸을 때 호출될 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // 탭 인덱스를 변경하고 화면을 다시 그리도록 요청
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- [핵심 1] WillPopScope 위젯으로 Scaffold를 감싸줍니다. ---
    // 이 위젯은 사용자의 '뒤로 가기' 액션을 감지하고 제어하는 역할을 합니다.
    return WillPopScope(
      // onWillPop 콜백은 사용자가 뒤로가기를 시도할 때마다 호출됩니다.
      onWillPop: () async {
        // 이 함수는 Future<bool>을 반환해야 합니다.
        // - true를 반환하면: 원래 하려던 뒤로가기 액션을 허용합니다.
        // - false를 반환하면: 뒤로가기 액션을 무시하고 아무 일도 일어나지 않습니다.

        // 여기서는 뒤로가기를 누르면 앱을 완전히 종료시키도록 명령합니다.
        SystemNavigator.pop();

        // 뒤로가기 액션 자체는 무시하도록 false를 반환합니다.
        return false;
      },
      child: Scaffold(
        // --- [핵심 2] IndexedStack을 사용하여 탭 간 상태를 유지합니다. ---
        // IndexedStack은 모든 자식 위젯을 메모리에 유지하고, index에 해당하는 위젯만 보여줍니다.
        // 탭을 전환해도 각 페이지의 스크롤 위치나 입력 상태가 초기화되지 않습니다.
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
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
      ),
    );
  }
}
