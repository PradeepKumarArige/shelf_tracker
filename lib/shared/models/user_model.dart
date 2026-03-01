class UserModel {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final bool notificationEnabled;
  final bool emailAlertsEnabled;
  final bool dealNotificationsEnabled;
  final int defaultExpiryDays;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.notificationEnabled = true,
    this.emailAlertsEnabled = true,
    this.dealNotificationsEnabled = true,
    this.defaultExpiryDays = 7,
    this.language = 'en',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'notification_enabled': notificationEnabled ? 1 : 0,
      'email_alerts_enabled': emailAlertsEnabled ? 1 : 0,
      'deal_notifications_enabled': dealNotificationsEnabled ? 1 : 0,
      'default_expiry_days': defaultExpiryDays,
      'language': language,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      avatarUrl: map['avatar_url'],
      notificationEnabled: map['notification_enabled'] == 1,
      emailAlertsEnabled: map['email_alerts_enabled'] == 1,
      dealNotificationsEnabled: map['deal_notifications_enabled'] == 1,
      defaultExpiryDays: map['default_expiry_days'] ?? 7,
      language: map['language'] ?? 'en',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    bool? notificationEnabled,
    bool? emailAlertsEnabled,
    bool? dealNotificationsEnabled,
    int? defaultExpiryDays,
    String? language,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      emailAlertsEnabled: emailAlertsEnabled ?? this.emailAlertsEnabled,
      dealNotificationsEnabled: dealNotificationsEnabled ?? this.dealNotificationsEnabled,
      defaultExpiryDays: defaultExpiryDays ?? this.defaultExpiryDays,
      language: language ?? this.language,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
