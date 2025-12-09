import 'package:flutter_test/flutter_test.dart';
import 'package:quicksplit/features/ocr/domain/services/receipt_parser.dart';

void main() {
  group('ReceiptParser', () {
    group('parseReceipt', () {
      test('parses simple receipt with 3 items', () {
        const rawText = '''
        RECEIPT
        Nasi Lemak        RM 12.50
        Teh Ais      x2   RM 6.00
        Sambal Egg        RM 8.50

        Subtotal          RM 26.00
        SST 6%            RM 1.56
        Total             RM 27.56
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.items.length, equals(3));
        expect(receipt.items[0].name, equals('Nasi Lemak'));
        expect(receipt.items[0].price, equals(12.50));
        expect(receipt.items[1].name, equals('Teh Ais'));
        expect(receipt.items[1].quantity, equals(2));
        expect(receipt.items[2].name, equals('Sambal Egg'));
        expect(receipt.items[2].price, equals(8.50));
      });

      test('handles Malaysian currency format (RM)', () {
        const rawText = '''
        Item A      RM 123.45
        Item B      RM 9.99
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.items[0].price, equals(123.45));
        expect(receipt.items[1].price, equals(9.99));
      });

      test('detects quantity patterns: x2, 2x, @2', () {
        const rawText = '''
        Nasi x2       RM 25.00
        Mee 3x        RM 15.00
        Teh @2        RM 4.00
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.items[0].quantity, equals(2));
        expect(receipt.items[1].quantity, equals(3));
        expect(receipt.items[2].quantity, equals(2));
      });

      test('handles comma-separated prices (Malaysian format)', () {
        const rawText = '''
        Item A      RM 123,45
        Item B      RM 9,99
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.items[0].price, equals(123.45));
        expect(receipt.items[1].price, equals(9.99));
      });

      test('extracts special rows (SST, Service Charge, Rounding)', () {
        const rawText = '''
        Item A        RM 100.00

        Subtotal      RM 100.00
        SST 6%        RM 6.00
        Service       RM 10.00
        Rounding      RM 0.04
        Total         RM 116.04
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.sst, equals(6.00));
        expect(receipt.serviceCharge, equals(10.00));
        expect(receipt.rounding, equals(0.04));
        expect(receipt.total, equals(116.04));
      });

      test('validates total vs calculated subtotal', () {
        const rawText = '''
        Item A        RM 50.00
        Item B        RM 50.00

        Total         RM 120.00
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.errors.isNotEmpty, true);
        expect(receipt.errors.any((e) => e.contains('mismatch')), true);
      });

      test('handles empty receipt gracefully', () {
        const rawText = '';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.items.isEmpty, true);
        expect(receipt.errors.isNotEmpty, true);
      });

      test('ignores header/footer text, extracts only items', () {
        const rawText = '''
        RESTAURANT ABC
        BLK 123 JALAN MERDEKA
        TEL: 03-1234-5678

        Item A        RM 45.00
        Item B        RM 55.00

        Thank you!
        Come again!
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.items.length, equals(2));
        expect(receipt.items[0].name, equals('Item A'));
        expect(receipt.items[1].name, equals('Item B'));
      });

      test('handles multi-word item names', () {
        const rawText = '''
        Fried Chicken Drumstick x2    RM 24.00
        Mixed Vegetable Stir Fry      RM 18.50
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.items[0].name, equals('Fried Chicken Drumstick'));
        expect(receipt.items[1].name, equals('Mixed Vegetable Stir Fry'));
      });

      test('calculates subtotal from items if not extracted', () {
        const rawText = '''
        Item A        RM 25.00
        Item B        RM 30.00
        Item C        RM 45.00
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.calculatedTotal, equals(100.00));
      });

      test('handles very large prices', () {
        const rawText = '''
        Catering Service (50 pax)    RM 2500.00
        Bar Tab                      RM 1250.50
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.items[0].price, equals(2500.00));
        expect(receipt.items[1].price, equals(1250.50));
      });

      test('handles single item prices like "9.99"', () {
        const rawText = '''
        Kopi       9.99
        Nasi       12.50
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.items[0].price, equals(9.99));
        expect(receipt.items[1].price, equals(12.50));
      });

      test('parses receipt with multiple quantities', () {
        const rawText = '''
        Coffee x3      RM 10.50
        Cake x2        RM 8.00
        Juice 5x       RM 15.00
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.items[0].quantity, equals(3));
        expect(receipt.items[1].quantity, equals(2));
        expect(receipt.items[2].quantity, equals(5));
      });

      test('calculates subtotal for items with quantities', () {
        const rawText = '''
        Item x2        RM 10.00
        Item x3        RM 5.00
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.items[0].subtotal, equals(20.00));
        expect(receipt.items[1].subtotal, equals(15.00));
      });

      test('handles receipt with only subtotal and total', () {
        const rawText = '''
        Item A        RM 50.00
        Item B        RM 30.00

        Subtotal      RM 80.00
        Total         RM 80.00
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        expect(receipt.subtotal, equals(80.00));
        expect(receipt.total, equals(80.00));
      });
    });
  });
}
