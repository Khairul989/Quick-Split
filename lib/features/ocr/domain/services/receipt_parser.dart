/// Core receipt parsing service for extracting structured data from raw OCR text
class ReceiptParser {
  static final RegExp _currencyPattern = RegExp(
    r'RM\s*(\d{1,6}[\.,]\d{2})',
    caseSensitive: false,
  );

  static final RegExp _pricePattern = RegExp(
    r'(\d{1,6}[\.,]\d{2})\s*$',
  );

  static final RegExp _quantityPattern = RegExp(
    r'^.*?(\d+)\s*[x×X]\s*|^.*?\s*[x×X]\s*(\d+)\s*|^.*?@\s*(\d+)',
  );

  static final RegExp _specialRowPattern = RegExp(
    r'^\s*(subtotal|total|sst|service(\s*charge)?|rounding|discount|tax|gst)\s',
    caseSensitive: false,
  );

  /// Main entry point: Parse raw OCR text into structured receipt
  static ParsedReceipt parseReceipt(String rawText) {
    if (rawText.trim().isEmpty) {
      return ParsedReceipt(
        items: const [],
        subtotal: 0.0,
        total: 0.0,
        sst: 0.0,
        serviceCharge: 0.0,
        rounding: 0.0,
        errors: const ['Receipt text is empty'],
      );
    }

    final lines = _cleanAndSplitText(rawText);
    final itemLines = _identifyItemLines(lines);
    final items = _extractItems(itemLines);
    final totals = _extractTotals(lines);

    return ParsedReceipt(
      items: items,
      subtotal: totals['subtotal'] ?? _calculateSubtotal(items),
      total: totals['total'] ?? 0.0,
      sst: totals['sst'] ?? 0.0,
      serviceCharge: totals['serviceCharge'] ?? 0.0,
      rounding: totals['rounding'] ?? 0.0,
      rawLines: lines,
      errors: _validateReceipt(items, totals),
    );
  }

  /// Step 1: Clean OCR text and split into lines
  static List<String> _cleanAndSplitText(String rawText) {
    return rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// Step 2: Identify which lines contain items (look for price patterns)
  static List<String> _identifyItemLines(List<String> lines) {
    return lines.where((line) {
      // Skip special rows (subtotal, total, etc.)
      if (_specialRowPattern.hasMatch(line)) {
        return false;
      }

      // Item lines must contain a currency pattern or price pattern at the end
      return _currencyPattern.hasMatch(line) || _pricePattern.hasMatch(line);
    }).toList();
  }

  /// Step 3: Extract individual items from item lines
  static List<ParsedItem> _extractItems(List<String> itemLines) {
    return itemLines.map((line) => _parseItemLine(line)).toList();
  }

  /// Parse a single item line into (name, quantity, price)
  static ParsedItem _parseItemLine(String line) {
    // Extract price (last currency or numeric pattern)
    final priceMatch = _currencyPattern.firstMatch(line) ??
        _pricePattern.firstMatch(line);

    if (priceMatch == null) {
      return ParsedItem(
        name: line,
        quantity: 1,
        price: 0.0,
        rawLine: line,
      );
    }

    final priceStr = priceMatch.group(1) ?? priceMatch.group(0) ?? '0.00';
    final price = _parsePrice(priceStr);

    // Extract quantity (look for patterns like 2x, x2, @2)
    final quantityMatch = _quantityPattern.firstMatch(line);
    int quantity = 1;

    if (quantityMatch != null) {
      // Try group 1 first (e.g., "2x" pattern: 2x Item)
      if (quantityMatch.group(1) != null) {
        quantity = int.tryParse(quantityMatch.group(1)!) ?? 1;
      }
      // Then group 2 (e.g., "x2" pattern: Item x2)
      else if (quantityMatch.group(2) != null) {
        quantity = int.tryParse(quantityMatch.group(2)!) ?? 1;
      }
      // Then group 3 (e.g., "@2" pattern: Item @2)
      else if (quantityMatch.group(3) != null) {
        quantity = int.tryParse(quantityMatch.group(3)!) ?? 1;
      }
    }

    // Extract item name (everything before price and quantity)
    String name = line;
    if (priceMatch.start > 0) {
      name = line.substring(0, priceMatch.start).trim();
    }

    // Remove quantity notation from name if it appears at the end
    name = name
        .replaceAll(RegExp(r'\s*\d+\s*[x×X]\s*$'), '')
        .replaceAll(RegExp(r'\s*[x×X]\s*\d+\s*$'), '')
        .replaceAll(RegExp(r'\s*@\s*\d+\s*$'), '')
        .trim();

    // Clean up name: remove common OCR artifacts
    name = _cleanItemName(name);

    return ParsedItem(
      name: name,
      quantity: quantity,
      price: price,
      rawLine: line,
    );
  }

  /// Parse price string "123.45" or "123,45" to double
  static double _parsePrice(String priceStr) {
    try {
      // Normalize: convert comma to period (Malaysian receipts use both)
      final normalized = priceStr.replaceAll(',', '.');
      return double.parse(normalized);
    } catch (_) {
      return 0.0;
    }
  }

  /// Clean up item names: remove common OCR artifacts
  static String _cleanItemName(String name) {
    // Remove leading/trailing special characters
    name = name.replaceAll(RegExp(r'^[\s\*\-\.]+'), '');
    name = name.replaceAll(RegExp(r'[\s\*\-\.]+$'), '');

    // Fix common OCR mistakes (these are examples)
    // "ltem" → "Item", "0" → "O"
    name = name.replaceAll(RegExp(r'\bl0\b', caseSensitive: false), 'lo');

    return name.trim();
  }

  /// Step 4: Extract totals from footer rows
  static Map<String, double> _extractTotals(List<String> lines) {
    final totals = <String, double>{};

    for (final line in lines) {
      if (_specialRowPattern.hasMatch(line)) {
        if (line.toLowerCase().contains('subtotal')) {
          totals['subtotal'] = _extractLastPrice(line);
        } else if (line.toLowerCase().contains('total')) {
          totals['total'] = _extractLastPrice(line);
        } else if (line.toLowerCase().contains('sst')) {
          totals['sst'] = _extractLastPrice(line);
        } else if (line.toLowerCase().contains('service')) {
          totals['serviceCharge'] = _extractLastPrice(line);
        } else if (line.toLowerCase().contains('rounding')) {
          totals['rounding'] = _extractLastPrice(line);
        }
      }
    }

    return totals;
  }

  /// Extract the last price from a line (for footer totals)
  static double _extractLastPrice(String line) {
    final matches = _currencyPattern.allMatches(line);
    if (matches.isNotEmpty) {
      final lastMatch = matches.last;
      return _parsePrice(lastMatch.group(1) ?? '0.00');
    }

    final matches2 = _pricePattern.allMatches(line);
    if (matches2.isNotEmpty) {
      final lastMatch = matches2.last;
      return _parsePrice(lastMatch.group(1) ?? '0.00');
    }

    return 0.0;
  }

  /// Calculate subtotal from items (if not explicitly found)
  static double _calculateSubtotal(List<ParsedItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  /// Validate parsed receipt for errors
  static List<String> _validateReceipt(
    List<ParsedItem> items,
    Map<String, double> totals,
  ) {
    final errors = <String>[];

    if (items.isEmpty) {
      errors.add('No items found in receipt');
    }

    final calculatedSubtotal = _calculateSubtotal(items);
    final extractedTotal = totals['total'] ?? 0.0;

    // Allow 10% variance (some receipts have formatting issues)
    if (extractedTotal > 0 && calculatedSubtotal > 0) {
      final variance = ((extractedTotal - calculatedSubtotal).abs() /
          calculatedSubtotal *
          100);
      if (variance > 10) {
        errors.add(
          'Total mismatch: calculated RM ${calculatedSubtotal.toStringAsFixed(2)} '
          'but found RM ${extractedTotal.toStringAsFixed(2)}',
        );
      }
    }

    return errors;
  }
}

/// Data classes for parsed results
class ParsedReceipt {
  final List<ParsedItem> items;
  final double subtotal;
  final double total;
  final double sst;
  final double serviceCharge;
  final double rounding;
  final List<String> rawLines;
  final List<String> errors;

  const ParsedReceipt({
    required this.items,
    required this.subtotal,
    required this.total,
    required this.sst,
    required this.serviceCharge,
    required this.rounding,
    this.rawLines = const [],
    this.errors = const [],
  });

  double get calculatedTotal =>
      subtotal + sst + serviceCharge + rounding;

  bool get isValid => errors.isEmpty;
}

class ParsedItem {
  final String name;
  final int quantity;
  final double price;
  final String rawLine;

  const ParsedItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.rawLine,
  });

  double get subtotal => price * quantity;
}
