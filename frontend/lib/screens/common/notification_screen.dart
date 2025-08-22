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
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends State<NotificationScreen> {
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

  // ===== 상위(AppBar)에서 호출할 공개 메서드 =====
  Future<void> markAllAsReadPublic() async {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('모든 알림을 읽음 처리했습니다.')),
    );
  }
  // ============================================

  // 알림 타입에 따라 다른 아이콘과 색상을 반환
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

  String _formatRelativeTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 내부 Scaffold/AppBar 제거 → 상위 PatientShell이 제공
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _notifications.isEmpty
          ? const Center(
        child: Text(
          '새로운 알림이 없습니다.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.separated(
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final n = _notifications[index];
          final style = _getNotificationStyle(n.type);

          return Ink(
            decoration: BoxDecoration(
              color: n.isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: n.isRead ? Colors.grey.shade300 : Colors.blue.shade100,
              ),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: CircleAvatar(
                backgroundColor: style.color,
                child: Icon(style.icon, color: Colors.white),
              ),
              title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.body),
                  const SizedBox(height: 4),
                  Text(
                    _formatRelativeTime(n.timestamp),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: n.isRead
                  ? const SizedBox.shrink()
                  : IconButton(
                tooltip: '읽음으로 표시',
                icon: const Icon(Icons.done_all),
                onPressed: () {
                  setState(() => n.isRead = true);
                },
              ),
              onTap: () {
                setState(() => n.isRead = true);
                // TODO: 알림 종류별 상세 화면 이동 로직 (예: 위험도 -> 위험도 화면)
              },
            ),
          );
        },
      ),
    );
  }
}
