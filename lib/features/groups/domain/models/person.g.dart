// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PersonAdapter extends TypeAdapter<Person> {
  @override
  final typeId = 2;

  @override
  Person read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Person(
      id: fields[0] as String?,
      name: fields[1] as String,
      emoji: fields[2] as String,
      createdAt: fields[3] as DateTime?,
      phoneNumber: fields[4] as String?,
      email: fields[5] as String?,
      contactId: fields[6] as String?,
      usageCount: fields[7] == null ? 0 : (fields[7] as num).toInt(),
      lastUsedAt: fields[8] as DateTime?,
      linkedUserId: fields[9] as String?,
      linkedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Person obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.phoneNumber)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.contactId)
      ..writeByte(7)
      ..write(obj.usageCount)
      ..writeByte(8)
      ..write(obj.lastUsedAt)
      ..writeByte(9)
      ..write(obj.linkedUserId)
      ..writeByte(10)
      ..write(obj.linkedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
