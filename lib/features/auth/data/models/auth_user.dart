import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AuthUser {
  final String uid;
  final String email;
  final String? name;
  final String? emoji;
  final String? photoUrl;
  final DateTime? createdAt;

  const AuthUser({
    required this.uid,
    required this.email,
    this.name,
    this.emoji,
    this.photoUrl,
    this.createdAt,
  });

  /// Convert from Firebase User to AuthUser
  factory AuthUser.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return AuthUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime,
    );
  }

  /// Convert to JSON for local storage/serialization
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'name': name,
    'emoji': emoji,
    'photoUrl': photoUrl,
    'createdAt': createdAt?.toIso8601String(),
  };

  /// Create from JSON
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    uid: json['uid'] as String,
    email: json['email'] as String,
    name: json['name'] as String?,
    emoji: json['emoji'] as String?,
    photoUrl: json['photoUrl'] as String?,
    createdAt: json['createdAt'] != null
      ? DateTime.parse(json['createdAt'] as String)
      : null,
  );

  /// Copy with method for updates
  AuthUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? emoji,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          name == other.name &&
          emoji == other.emoji &&
          photoUrl == other.photoUrl &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      name.hashCode ^
      emoji.hashCode ^
      photoUrl.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'AuthUser(uid: $uid, email: $email, name: $name, emoji: $emoji)';
}
