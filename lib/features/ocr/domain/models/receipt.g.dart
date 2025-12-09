// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReceiptAdapter extends TypeAdapter<Receipt> {
  @override
  final typeId = 0;

  @override
  Receipt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Receipt(
      id: fields[0] as String?,
      merchantName: fields[1] == null ? 'Unknown' : fields[1] as String,
      captureDate: fields[2] as DateTime?,
      items: (fields[3] as List).cast<ReceiptItem>(),
      subtotal: (fields[4] as num).toDouble(),
      sst: fields[5] == null ? 0.0 : (fields[5] as num).toDouble(),
      serviceCharge: fields[6] == null ? 0.0 : (fields[6] as num).toDouble(),
      rounding: fields[7] == null ? 0.0 : (fields[7] as num).toDouble(),
      total: (fields[8] as num).toDouble(),
      imagePath: fields[9] as String?,
      ocrRawText: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Receipt obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.merchantName)
      ..writeByte(2)
      ..write(obj.captureDate)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.subtotal)
      ..writeByte(5)
      ..write(obj.sst)
      ..writeByte(6)
      ..write(obj.serviceCharge)
      ..writeByte(7)
      ..write(obj.rounding)
      ..writeByte(8)
      ..write(obj.total)
      ..writeByte(9)
      ..write(obj.imagePath)
      ..writeByte(10)
      ..write(obj.ocrRawText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReceiptItemAdapter extends TypeAdapter<ReceiptItem> {
  @override
  final typeId = 1;

  @override
  ReceiptItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReceiptItem(
      id: fields[0] as String?,
      name: fields[1] as String,
      quantity: (fields[2] as num).toInt(),
      price: (fields[3] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
