// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_invite.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupInviteAdapter extends TypeAdapter<GroupInvite> {
  @override
  final typeId = 12;

  @override
  GroupInvite read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupInvite(
      id: fields[0] as String?,
      groupId: fields[1] as String,
      groupName: fields[2] as String,
      invitedBy: fields[3] as String,
      invitedByName: fields[4] as String,
      inviteCode: fields[5] as String,
      status: fields[6] as String?,
      createdAt: fields[7] as DateTime?,
      expiresAt: fields[8] as DateTime?,
      acceptedBy: fields[9] as String?,
      acceptedAt: fields[10] as DateTime?,
      invitedEmail: fields[11] as String?,
      invitedPhone: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GroupInvite obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.groupName)
      ..writeByte(3)
      ..write(obj.invitedBy)
      ..writeByte(4)
      ..write(obj.invitedByName)
      ..writeByte(5)
      ..write(obj.inviteCode)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.expiresAt)
      ..writeByte(9)
      ..write(obj.acceptedBy)
      ..writeByte(10)
      ..write(obj.acceptedAt)
      ..writeByte(11)
      ..write(obj.invitedEmail)
      ..writeByte(12)
      ..write(obj.invitedPhone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupInviteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
