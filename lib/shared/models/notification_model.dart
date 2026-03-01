enum NotificationType { expiry, deal, reminder, system }

class NotificationModel {
  final String id;
  final String userId;
  final String? itemId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.itemId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.scheduledAt,
    this.sentAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'item_id': itemId,
      'type': type.name,
      'title': title,
      'body': body,
      'is_read': isRead ? 1 : 0,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      userId: map['user_id'],
      itemId: map['item_id'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.system,
      ),
      title: map['title'],
      body: map['body'],
      isRead: map['is_read'] == 1,
      scheduledAt: map['scheduled_at'] != null 
          ? DateTime.parse(map['scheduled_at']) 
          : null,
      sentAt: map['sent_at'] != null 
          ? DateTime.parse(map['sent_at']) 
          : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? itemId,
    NotificationType? type,
    String? title,
    String? body,
    bool? isRead,
    DateTime? scheduledAt,
    DateTime? sentAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      createdAt: createdAt,
    );
  }
}
