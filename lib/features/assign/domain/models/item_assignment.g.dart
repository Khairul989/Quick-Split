// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_assignment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemAssignmentAdapter extends TypeAdapter<ItemAssignment> {
  @override
  final typeId = 4;

  @override
  ItemAssignment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemAssignment(
      itemId: fields[0] as String,
      assignedPersonIds: (fields[1] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ItemAssignment obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.itemId)
      ..writeByte(1)
      ..write(obj.assignedPersonIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemAssignmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
