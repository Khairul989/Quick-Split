// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SplitSessionAdapter extends TypeAdapter<SplitSession> {
  @override
  final typeId = 5;

  @override
  SplitSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SplitSession(
      id: fields[0] as String?,
      receiptId: fields[1] as String,
      groupId: fields[2] as String?,
      participantPersonIds: (fields[3] as List).cast<String>(),
      assignments: (fields[4] as List).cast<ItemAssignment>(),
      calculatedShares: (fields[5] as List).cast<PersonShare>(),
      createdAt: fields[6] as DateTime?,
      isSaved: fields[7] == null ? false : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SplitSession obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.receiptId)
      ..writeByte(2)
      ..write(obj.groupId)
      ..writeByte(3)
      ..write(obj.participantPersonIds)
      ..writeByte(4)
      ..write(obj.assignments)
      ..writeByte(5)
      ..write(obj.calculatedShares)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isSaved);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
