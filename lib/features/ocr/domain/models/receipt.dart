import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

part 'receipt.g.dart';

@HiveType(typeId: 0)
class Receipt extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String merchantName;

  @HiveField(2)
  final DateTime captureDate;

  @HiveField(3)
  final List<ReceiptItem> items;

  @HiveField(4)
  final double subtotal;

  @HiveField(5)
  final double sst;

  @HiveField(6)
  final double serviceCharge;

  @HiveField(7)
  final double rounding;

  @HiveField(8)
  final double total;

  @HiveField(9)
  final String? imagePath;

  @HiveField(10)
  final String? ocrRawText;

  Receipt({
    String? id,
    this.merchantName = 'Unknown',
    DateTime? captureDate,
    required this.items,
    required this.subtotal,
    this.sst = 0.0,
    this.serviceCharge = 0.0,
    this.rounding = 0.0,
    required this.total,
    this.imagePath,
    this.ocrRawText,
  })  : id = id ?? const Uuid().v4(),
        captureDate = captureDate ?? DateTime.now();

  double get calculatedSubtotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get calculatedTotal =>
      calculatedSubtotal + sst + serviceCharge + rounding;

  Receipt copyWith({
    String? merchantName,
    List<ReceiptItem>? items,
    double? subtotal,
    double? sst,
    double? serviceCharge,
    double? rounding,
    double? total,
    String? imagePath,
    String? ocrRawText,
  }) {
    return Receipt(
      id: id,
      merchantName: merchantName ?? this.merchantName,
      captureDate: captureDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      sst: sst ?? this.sst,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      rounding: rounding ?? this.rounding,
      total: total ?? this.total,
      imagePath: imagePath ?? this.imagePath,
      ocrRawText: ocrRawText ?? this.ocrRawText,
    );
  }
}

@HiveType(typeId: 1)
class ReceiptItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late int quantity;

  @HiveField(3)
  late double price;

  ReceiptItem({
    String? id,
    required this.name,
    required this.quantity,
    required this.price,
  }) : id = id ?? const Uuid().v4();

  double get subtotal => price * quantity;

  ReceiptItem copyWith({
    String? name,
    int? quantity,
    double? price,
  }) {
    return ReceiptItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}
