import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _selectedIndex = 0;

  // RiskScoreScreen의 State 클래스에 접근하기 위한 GlobalKey
  final GlobalKey<RiskScoreScreenState> _riskScoreScreenKey = GlobalKey();

  // AppBar 제목 목록
  final List<String> _appBarTitles = const ['욕창 위험도', '알림', '식생활 정보', '설정'];

  // BottomNavigationBar에 표시할 페이지 위젯 목록
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // initState에서 페이지 목록을 초기화합니다.
    _widgetOptions = <Widget>[
      // --- [핵심] onStateChanged 콜백에 setState 전달 ---
      // RiskScoreScreen 위젯을 생성할 때, onStateChanged라는 파라미터에
      // PatientShell 자신의 상태를 갱신하는 setState(() {}) 함수를 전달합니다.
      RiskScoreScreen(
        key: _riskScoreScreenKey,
        onStateChanged: () {
          // 이 함수는 RiskScoreScreen 내부에서 _updateState가 호출될 때마다 실행됩니다.
          // 빈 setState라도 호출되면, PatientShell의 build 메서드가 다시 실행되어
          // AppBar의 버튼 텍스트와 아이콘을 최신 상태로 업데이트합니다.
          setState(() {});
        },
      ),
      const NotificationScreen(),
      const DietInfoScreen(),
      const SettingsScreen(),
    ];
  }

  // 탭이 눌렸을 때 호출될 함수
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
          // 현재 선택된 탭이 0번('위험도')일 때만 '패드 연결' 버튼을 보여줍니다.
          actions: _selectedIndex == 0
              ? [
            TextButton.icon(
              // _riskScoreScreenKey.currentState를 통해 RiskScoreScreen의 상태에 접근합니다.
              // '?'는 key.currentState가 아직 빌드되지 않아 null일 경우를 대비한 안전장치입니다.
              icon: Icon(
                  _riskScoreScreenKey.currentState?.getConnectIcon() ?? Icons.bluetooth_disabled,
                  color: Colors.blue
              ),
              label: Text(
                _riskScoreScreenKey.currentState?.getConnectButtonText() ?? '패드 연결',
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              onPressed: () {
                // 버튼을 누르면, GlobalKey를 통해 RiskScoreScreen 내부의 함수를 직접 호출합니다.
                _riskScoreScreenKey.currentState?.navigateToScanScreen();
              },
            ),
            const SizedBox(width: 8),
          ]
              : null, // '위험도' 탭이 아닐 때는 아무 버튼도 보여주지 않습니다.
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
