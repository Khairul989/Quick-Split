class UserProfile {
  final String name;
  final String? email;
  final String emoji;
  final DateTime createdAt;
  final String? phoneNumber;
  final DateTime? updatedAt;
  final List<String> fcmTokens;

  const UserProfile({
    required this.name,
    this.email,
    required this.emoji,
    required this.createdAt,
    this.phoneNumber,
    this.updatedAt,
    this.fcmTokens = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'emoji': emoji,
    'createdAt': createdAt.toIso8601String(),
    'phoneNumber': phoneNumber,
    'updatedAt': updatedAt?.toIso8601String(),
    'fcmTokens': fcmTokens,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String,
    email: json['email'] as String?,
    emoji: json['emoji'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    phoneNumber: json['phoneNumber'] as String?,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    fcmTokens: List<String>.from((json['fcmTokens'] as List<dynamic>?) ?? []),
  );

  UserProfile copyWith({
    String? name,
    String? email,
    String? emoji,
    DateTime? createdAt,
    String? phoneNumber,
    DateTime? updatedAt,
    List<String>? fcmTokens,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          email == other.email &&
          emoji == other.emoji &&
          createdAt == other.createdAt &&
          phoneNumber == other.phoneNumber &&
          updatedAt == other.updatedAt &&
          fcmTokens == other.fcmTokens;

  @override
  int get hashCode =>
      name.hashCode ^
      email.hashCode ^
      emoji.hashCode ^
      createdAt.hashCode ^
      phoneNumber.hashCode ^
      updatedAt.hashCode ^
      fcmTokens.hashCode;

  /// Convert UserProfile to Firestore format
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'emoji': emoji,
    'createdAt': createdAt.toIso8601String(),
    'phoneNumber': phoneNumber,
    'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    'fcmTokens': fcmTokens,
  };

  /// Create UserProfile from Firestore document
  factory UserProfile.fromFirestore(Map<String, dynamic> data) => UserProfile(
    name: data['name'] as String,
    email: data['email'] as String?,
    emoji: data['emoji'] as String,
    createdAt: DateTime.parse(data['createdAt'] as String),
    phoneNumber: data['phoneNumber'] as String?,
    updatedAt: data['updatedAt'] != null
        ? DateTime.parse(data['updatedAt'] as String)
        : null,
    fcmTokens: List<String>.from((data['fcmTokens'] as List<dynamic>?) ?? []),
  );

  bool get hasPhone => phoneNumber != null && phoneNumber!.isNotEmpty;

  String get displayPhone => phoneNumber ?? 'Not provided';

  /// Add FCM token if not already present
  UserProfile addFcmToken(String token) {
    if (!fcmTokens.contains(token)) {
      return copyWith(fcmTokens: [...fcmTokens, token]);
    }
    return this;
  }

  /// Remove FCM token if present
  UserProfile removeFcmToken(String token) {
    if (fcmTokens.contains(token)) {
      return copyWith(fcmTokens: fcmTokens.where((t) => t != token).toList());
    }
    return this;
  }
}
