import 'package:flutter/material.dart';
import 'package:smart_pad/screens/login/login_screen.dart'; // 우리가 만들 로그인 화면

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '스마트 욕창 방지 앱',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginPage(), // 앱이 시작되면 LoginPage를 보여줌
    );
  }
}
