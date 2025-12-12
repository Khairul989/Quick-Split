// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person_share.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PersonShareAdapter extends TypeAdapter<PersonShare> {
  @override
  final typeId = 6;

  @override
  PersonShare read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PersonShare(
      personId: fields[0] as String,
      personName: fields[1] as String,
      personEmoji: fields[2] as String,
      itemsSubtotal: (fields[3] as num).toDouble(),
      sst: (fields[4] as num).toDouble(),
      serviceCharge: (fields[5] as num).toDouble(),
      rounding: (fields[6] as num).toDouble(),
      total: (fields[7] as num).toDouble(),
      assignedItemIds: (fields[8] as List).cast<String>(),
      paymentStatus: fields[9] == null
          ? PaymentStatus.unpaid
          : fields[9] as PaymentStatus,
      amountPaid: (fields[10] as num?)?.toDouble(),
      lastPaidAt: fields[11] as DateTime?,
      paymentNotes: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PersonShare obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.personId)
      ..writeByte(1)
      ..write(obj.personName)
      ..writeByte(2)
      ..write(obj.personEmoji)
      ..writeByte(3)
      ..write(obj.itemsSubtotal)
      ..writeByte(4)
      ..write(obj.sst)
      ..writeByte(5)
      ..write(obj.serviceCharge)
      ..writeByte(6)
      ..write(obj.rounding)
      ..writeByte(7)
      ..write(obj.total)
      ..writeByte(8)
      ..write(obj.assignedItemIds)
      ..writeByte(9)
      ..write(obj.paymentStatus)
      ..writeByte(10)
      ..write(obj.amountPaid)
      ..writeByte(11)
      ..write(obj.lastPaidAt)
      ..writeByte(12)
      ..write(obj.paymentNotes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonShareAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
