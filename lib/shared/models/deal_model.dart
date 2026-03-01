class DealModel {
  final String id;
  final String title;
  final String? description;
  final String store;
  final String discount;
  final String? category;
  final String? imageUrl;
  final String? link;
  final DateTime? startsAt;
  final DateTime expiresAt;
  final bool isFeatured;
  final DateTime createdAt;

  DealModel({
    required this.id,
    required this.title,
    this.description,
    required this.store,
    required this.discount,
    this.category,
    this.imageUrl,
    this.link,
    this.startsAt,
    required this.expiresAt,
    this.isFeatured = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get daysRemaining {
    return expiresAt.difference(DateTime.now()).inDays;
  }

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  bool get isActive {
    final now = DateTime.now();
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    return !isExpired;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'store': store,
      'discount': discount,
      'category': category,
      'image_url': imageUrl,
      'link': link,
      'starts_at': startsAt?.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_featured': isFeatured ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DealModel.fromMap(Map<String, dynamic> map) {
    return DealModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      store: map['store'],
      discount: map['discount'],
      category: map['category'],
      imageUrl: map['image_url'],
      link: map['link'],
      startsAt: map['starts_at'] != null ? DateTime.parse(map['starts_at']) : null,
      expiresAt: DateTime.parse(map['expires_at']),
      isFeatured: map['is_featured'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  DealModel copyWith({
    String? id,
    String? title,
    String? description,
    String? store,
    String? discount,
    String? category,
    String? imageUrl,
    String? link,
    DateTime? startsAt,
    DateTime? expiresAt,
    bool? isFeatured,
  }) {
    return DealModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      store: store ?? this.store,
      discount: discount ?? this.discount,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      link: link ?? this.link,
      startsAt: startsAt ?? this.startsAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt,
    );
  }
}
