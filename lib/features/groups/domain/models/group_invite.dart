import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

part 'group_invite.g.dart';

/// Status of a group invite
enum InviteStatus { pending, accepted, expired, cancelled }

/// GroupInvite represents an invitation to join a group
/// Stored in both Hive (local) and Firestore (sync)
@HiveType(typeId: 12)
class GroupInvite extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  late String groupId;

  @HiveField(2)
  late String groupName;

  @HiveField(3)
  late String invitedBy;

  @HiveField(4)
  late String invitedByName;

  @HiveField(5)
  late String inviteCode;

  @HiveField(6)
  late String status;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  late DateTime expiresAt;

  @HiveField(9)
  String? acceptedBy;

  @HiveField(10)
  DateTime? acceptedAt;

  @HiveField(11)
  String? invitedEmail;

  @HiveField(12)
  String? invitedPhone;

  GroupInvite({
    String? id,
    required this.groupId,
    required this.groupName,
    required this.invitedBy,
    required this.invitedByName,
    required this.inviteCode,
    String? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.acceptedBy,
    this.acceptedAt,
    this.invitedEmail,
    this.invitedPhone,
  }) : id = id ?? const Uuid().v4(),
       status = status ?? 'pending',
       createdAt = createdAt ?? DateTime.now(),
       expiresAt = expiresAt ?? DateTime.now().add(const Duration(days: 7));

  /// Check if invite has expired
  bool get isExpired =>
      status == 'expired' ||
      (status == 'pending' && DateTime.now().isAfter(expiresAt));

  /// Check if invite is still pending and valid
  bool get isValid => status == 'pending' && !isExpired;

  /// Check if invite has been accepted
  bool get isAccepted => status == 'accepted';

  /// Get remaining days until expiry
  int get daysUntilExpiry {
    if (isExpired) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }

  /// Create a copy with updated fields
  GroupInvite copyWith({
    String? groupId,
    String? groupName,
    String? invitedBy,
    String? invitedByName,
    String? inviteCode,
    String? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? acceptedBy,
    DateTime? acceptedAt,
    String? invitedEmail,
    String? invitedPhone,
  }) {
    return GroupInvite(
      id: id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedByName: invitedByName ?? this.invitedByName,
      inviteCode: inviteCode ?? this.inviteCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      invitedEmail: invitedEmail ?? this.invitedEmail,
      invitedPhone: invitedPhone ?? this.invitedPhone,
    );
  }

  /// Convert GroupInvite to Firestore format
  Map<String, dynamic> toFirestore() => {
    'groupId': groupId,
    'groupName': groupName,
    'invitedBy': invitedBy,
    'invitedByName': invitedByName,
    'inviteCode': inviteCode,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'acceptedBy': acceptedBy,
    'acceptedAt': acceptedAt?.toIso8601String(),
    'invitedEmail': invitedEmail,
    'invitedPhone': invitedPhone,
  };

  /// Create GroupInvite from Firestore document data
  factory GroupInvite.fromFirestore(Map<String, dynamic> data) {
    return GroupInvite(
      id: data['id'] as String? ?? const Uuid().v4(),
      groupId: data['groupId'] as String? ?? '',
      groupName: data['groupName'] as String? ?? '',
      invitedBy: data['invitedBy'] as String? ?? '',
      invitedByName: data['invitedByName'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      expiresAt: data['expiresAt'] != null
          ? DateTime.parse(data['expiresAt'] as String)
          : DateTime.now().add(const Duration(days: 7)),
      acceptedBy: data['acceptedBy'] as String?,
      acceptedAt: data['acceptedAt'] != null
          ? DateTime.parse(data['acceptedAt'] as String)
          : null,
      invitedEmail: data['invitedEmail'] as String?,
      invitedPhone: data['invitedPhone'] as String?,
    );
  }

  /// Create GroupInvite from JSON (for API responses)
  factory GroupInvite.fromJson(Map<String, dynamic> json) {
    return GroupInvite(
      id: json['id'] as String? ?? const Uuid().v4(),
      groupId: json['groupId'] as String? ?? '',
      groupName: json['groupName'] as String? ?? '',
      invitedBy: json['invitedBy'] as String? ?? '',
      invitedByName: json['invitedByName'] as String? ?? '',
      inviteCode: json['inviteCode'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now().add(const Duration(days: 7)),
      acceptedBy: json['acceptedBy'] as String?,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      invitedEmail: json['invitedEmail'] as String?,
      invitedPhone: json['invitedPhone'] as String?,
    );
  }

  /// Convert GroupInvite to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'groupId': groupId,
    'groupName': groupName,
    'invitedBy': invitedBy,
    'invitedByName': invitedByName,
    'inviteCode': inviteCode,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'acceptedBy': acceptedBy,
    'acceptedAt': acceptedAt?.toIso8601String(),
    'invitedEmail': invitedEmail,
    'invitedPhone': invitedPhone,
  };
}
