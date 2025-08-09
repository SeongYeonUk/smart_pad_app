import 'package:flutter/material.dart';

// 가상의 알림 데이터 모델 (나중에는 서버 또는 로컬 DB에서 받아옵니다)
enum NotificationType { risk, fall, system }

class DummyNotification {
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead; // 사용자가 읽었는지 여부

  DummyNotification({
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // TODO: 실제로는 서버 API 또는 로컬 DB에서 알림 목록을 받아와야 합니다.
  final List<DummyNotification> _notifications = [
    DummyNotification(
      title: '욕창 위험도 경고',
      body: '등 부위의 압력 수치가 85점을 초과했습니다. 자세 변경이 필요합니다.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      type: NotificationType.risk,
    ),
    DummyNotification(
      title: '낙상 감지 시스템 작동',
      body: '낙상이 감지되어 보호자에게 알림을 전송했습니다.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      type: NotificationType.fall,
      isRead: true,
    ),
    DummyNotification(
      title: '시스템 점검 안내',
      body: '내일 오전 3시에 정기 시스템 점검이 있을 예정입니다.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      type: NotificationType.system,
      isRead: true,
    ),
    DummyNotification(
      title: '욕창 위험도 주의',
      body: '엉덩이 부위의 습도가 높아 주의가 필요합니다.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.risk,
      isRead: true,
    ),
  ];

  // 알림 타입에 따라 다른 아이콘과 색상을 반환하는 헬퍼 클래스
  ({IconData icon, Color color}) _getNotificationStyle(NotificationType type) {
    switch (type) {
      case NotificationType.risk:
        return (icon: Icons.warning_amber_rounded, color: Colors.orange.shade700);
      case NotificationType.fall:
        return (icon: Icons.personal_injury, color: Colors.red.shade700);
      case NotificationType.system:
        return (icon: Icons.info_outline, color: Colors.blue.shade700);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          // 모든 알림을 읽음 처리하는 버튼
          TextButton(
            onPressed: () {
              setState(() {
                for (var notification in _notifications) {
                  notification.isRead = true;
                }
              });
            },
            child: const Text('모두 읽음'),
          )
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
        child: Text(
          '새로운 알림이 없습니다.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final style = _getNotificationStyle(notification.type);

          return ListTile(
            // 읽지 않은 알림은 배경색을 다르게 표시
            tileColor: notification.isRead ? null : Colors.blue.withOpacity(0.05),
            leading: CircleAvatar(
              backgroundColor: style.color,
              child: Icon(style.icon, color: Colors.white),
            ),
            title: Text(
              notification.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.body),
                const SizedBox(height: 4),
                Text(
                  // TODO: 시간 표시를 '5분 전', '1시간 전' 등으로 바꿔주는 timeago 패키지 사용 추천
                  '${notification.timestamp.hour}:${notification.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () {
              // 알림을 탭하면 읽음 처리
              setState(() {
                notification.isRead = true;
              });
              // TODO: 알림 종류에 따라 관련된 상세 화면으로 이동하는 로직 추가 가능
              // 예: 위험도 알림 -> 위험도 점수 화면으로 이동
            },
          );
        },
      ),
    );
  }
}
