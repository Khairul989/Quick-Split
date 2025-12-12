class UserProfile {
  final String name;
  final String? email;
  final String emoji;
  final DateTime createdAt;

  const UserProfile({
    required this.name,
    this.email,
    required this.emoji,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'emoji': emoji,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String,
    email: json['email'] as String?,
    emoji: json['emoji'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  UserProfile copyWith({
    String? name,
    String? email,
    String? emoji,
    DateTime? createdAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
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
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      name.hashCode ^ email.hashCode ^ emoji.hashCode ^ createdAt.hashCode;
}
