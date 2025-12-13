// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_match.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContactMatchAdapter extends TypeAdapter<ContactMatch> {
  @override
  final typeId = 11;

  @override
  ContactMatch read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContactMatch(
      personId: fields[0] as String,
      userId: fields[1] as String,
      matchedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ContactMatch obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.personId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.matchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactMatchAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
