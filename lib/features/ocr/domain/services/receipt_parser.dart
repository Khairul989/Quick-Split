import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Core receipt parsing service for extracting structured data from OCR text
class ReceiptParser {
  static final RegExp _currencyPattern = RegExp(
    r'(?:CHF|EUR|€|USD|\$|GBP|£|RM|[A-Z]{3})\s*(\d{1,6}[\.,]\d{2})',
    caseSensitive: false,
  );

  static final RegExp _europeanPattern = RegExp(
    r'[àa@]\s*(\d{1,6}[\.,]\d{2})',
    caseSensitive: false,
  );

  static final RegExp _pricePattern = RegExp(
    r'(\d{1,6}[\.,]\d{2})\s*$',
  );

  static final RegExp _quantityPattern = RegExp(
    r'^.*?(\d+)\s*[x×X]\s*|^.*?\s*[x×X]\s*(\d+)\s*|^.*?@\s*(\d+)',
  );

  static final RegExp _specialRowPattern = RegExp(
    r'^\s*(subtotal|total|sst|service(\s*charge)?|rounding|discount|tax|gst|vat|mwst|incl|inclusive)[\s\.\:]',
    caseSensitive: false,
  );

  /// Context-aware total price extraction pattern (improvement #4)
  /// Matches patterns like "Total: 50.99", "Grand Total CHF 50.99", etc.
  static final RegExp _totalPricePattern = RegExp(
    r'(Total|Grand\s*Total|Balance\s*Due|Amount\s*Due|Net\s*Total|Final\s*Total|Order\s*Total|Invoice\s*Total|Total\s*Amount)[\s\.\:]*([+-]?\d{1,3}(?:,?\d{3})*(?:[\.,]\d{2})?)',
    caseSensitive: false,
  );

  /// Blacklist of words indicating non-item lines (improvement #1)
  /// These words commonly appear in receipts but should not be extracted as item names
  static final List<String> _invalidItemWords = [
    'total', 'subtotal', 'grand total', 'change', 'amount', 'receipt',
    'phone', 'fax', 'gst', 'tax', 'sst', 'service', 'delivery', 'discount',
    'payment', 'cash', 'card', 'visa', 'mastercard', 'scan', 'merchant',
    'store', 'outlet', 'shop', 'thank you', 'welcome', 'bill', 'invoice',
  ];

  /// Merchant indicator words (improvement #6)
  /// Used to identify and skip lines containing merchant names
  static final List<String> _merchantWords = [
    'sdn bhd', 'enterprise', 'trading', 'company', 'limited', 'inc',
    'corporation', 'co.', 'llc', 'restaurant', 'cafe', 'bistro',
    'hotel', 'resort', 'mall', 'plaza', 'centre', 'center',
  ];

  /// Parse RecognizedText from Google ML Kit using element-based extraction
  static ParsedReceipt parseReceiptFromRecognizedText(
    RecognizedText recognizedText,
  ) {
    if (recognizedText.blocks.isEmpty || recognizedText.text.isEmpty) {
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

    final priceElements = _extractPriceElementsFromRecognizedText(recognizedText);
    final items = _buildItemsFromPriceElements(priceElements);
    final totals = _extractTotalsFromText(recognizedText.text);

    return ParsedReceipt(
      items: items,
      subtotal: totals['subtotal'] ?? _calculateSubtotal(items),
      total: totals['total'] ?? 0.0,
      sst: totals['sst'] ?? 0.0,
      serviceCharge: totals['serviceCharge'] ?? 0.0,
      rounding: totals['rounding'] ?? 0.0,
      rawText: recognizedText.text,
      errors: _validateReceipt(items, totals),
    );
  }

  /// Main entry point: Parse raw OCR text into structured receipt (backward compatible)
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

  /// Extract price elements from recognized text blocks
  /// Returns list of price elements with surrounding context (preceding/following elements)
  /// Extracts price elements from ALL lines (no filtering)
  static List<_PriceElement> _extractPriceElementsFromRecognizedText(
    RecognizedText recognizedText,
  ) {
    final priceElements = <_PriceElement>[];

    print('\n💰 [PARSER] Extracting price elements...');
    int totalLines = 0;
    for (final block in recognizedText.blocks) {
      totalLines += block.lines.length;
    }
    print('  - Total lines to process: $totalLines');

    for (final block in recognizedText.blocks) {
      for (int lineIndex = 0; lineIndex < block.lines.length; lineIndex++) {
        final line = block.lines[lineIndex];
        for (int i = 0; i < line.elements.length; i++) {
          final element = line.elements[i];
          final text = element.text;

          // Try to match currency pattern first, then fallback to price pattern
          final currencyMatch = _currencyPattern.firstMatch(text);
          final priceMatch = currencyMatch ?? _pricePattern.firstMatch(text);

          if (priceMatch != null && _isValidPrice(text)) {
            final priceStr = currencyMatch?.group(1) ?? priceMatch.group(1) ?? '0.00';
            final price = _parsePrice(priceStr);

            print('  ✓ Found price: $price on line: "${line.text}"');

            priceElements.add(
              _PriceElement(
                price: price,
                elementIndex: i,
                line: line,
                block: block,
                lineIndexInBlock: lineIndex,
                element: element,
                precedingElements: i > 0 ? line.elements.sublist(0, i) : [],
                followingElements:
                    i < line.elements.length - 1 ? line.elements.sublist(i + 1) : [],
              ),
            );
          }
        }
      }
    }

    // Improvement #5: Sort price elements by value (descending - highest first)
    // Highest price is likely the total, which helps identify line totals vs unit prices
    priceElements.sort((a, b) => b.price.compareTo(a.price));

    print('  - Total price elements extracted: ${priceElements.length}');
    if (priceElements.isEmpty) {
      print('  ⚠️ WARNING: No price elements found!');
    }

    return priceElements;
  }

  /// Build items from price elements by reconstructing names from surrounding elements
  /// Improvements: #1 (invalid word blacklist), #3 (aggressive validation), #6 (merchant filtering)
  static List<ParsedItem> _buildItemsFromPriceElements(List<_PriceElement> priceElements) {
    final items = <ParsedItem>[];

    print('\n🏗️ [PARSER] Building items from ${priceElements.length} price elements...');

    // Track seen prices to avoid duplicates
    final seenPrices = <String>{};

    for (final priceElement in priceElements) {
      // Skip duplicate prices (receipts often show prices twice)
      final priceKey = '${priceElement.price}_${priceElement.line.text}';
      if (seenPrices.contains(priceKey)) {
        print('  ❌ Skipped (duplicate price): ${priceElement.price} on line "${priceElement.line.text}"');
        continue;
      }
      seenPrices.add(priceKey);

      // Reconstruct item name from elements BEFORE the price
      String itemName = priceElement.precedingElements
          .map((e) => e.text)
          .join(' ')
          .trim();

      // If no preceding elements, try following elements (price might be at start)
      if (itemName.isEmpty && priceElement.followingElements.isNotEmpty) {
        itemName = priceElement.followingElements
            .map((e) => e.text)
            .join(' ')
            .trim();
      }

      // Fall back to full line text if still empty
      if (itemName.isEmpty) {
        itemName = priceElement.line.text.replaceAll(priceElement.element.text, '').trim();
      }

      // If item name is still empty or very short (< 3 chars), look at PREVIOUS line
      if (itemName.replaceAll(RegExp(r'[^\w]'), '').length < 3 &&
          priceElement.lineIndexInBlock > 0) {
        final previousLine = priceElement.block.lines[priceElement.lineIndexInBlock - 1];
        final previousLineText = previousLine.text.trim();

        // Use previous line if it doesn't contain a price (likely an item name)
        if (!_currencyPattern.hasMatch(previousLineText) &&
            !_pricePattern.hasMatch(previousLineText)) {
          print('  ℹ️ Using previous line for item name: "$previousLineText"');
          itemName = previousLineText;
        }
      }

      // Filter 1: Skip special rows (tax, total, subtotal, etc.)
      if (_specialRowPattern.hasMatch(itemName) ||
          _specialRowPattern.hasMatch(priceElement.line.text)) {
        print('  ❌ Skipped (special row): "${priceElement.line.text}"');
        continue;  // Skip this item
      }

      // Filter 2: Skip if item name is just currency code or very short
      final cleanedForCheck = itemName.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      if (cleanedForCheck.length < 2 ||
          _isCurrencyCode(cleanedForCheck)) {
        print('  ❌ Skipped (too short/currency): "$itemName"');
        continue;  // Skip this item
      }

      // Improvement #1: Filter by invalid item words (blacklist filtering)
      final lowerName = itemName.toLowerCase();
      if (_invalidItemWords.any((word) => lowerName.contains(word))) {
        print('  ❌ Skipped (invalid word): "$itemName" (matched: ${_invalidItemWords.where((w) => lowerName.contains(w)).join(", ")})');
        continue;  // Skip lines with invalid item words (total, tax, payment, etc.)
      }

      // Improvement #6: Filter by merchant words (skip likely merchant names)
      if (_merchantWords.any((word) => lowerName.contains(word))) {
        print('  ❌ Skipped (merchant word): "$itemName" (matched: ${_merchantWords.where((w) => lowerName.contains(w)).join(", ")})');
        continue;  // Skip lines with merchant indicator words
      }

      // Filter 3: For European "à" format, prefer unit price (price AFTER "à")
      // If line contains "à" and this price comes AFTER it, it's likely the total - skip it
      if (itemName.contains('à') || itemName.contains('@')) {
        // Check if this price element comes after "à" symbol
        bool priceAfterSeparator = false;
        for (int i = 0; i < priceElement.precedingElements.length; i++) {
          if (priceElement.precedingElements[i].text.contains('à') ||
              priceElement.precedingElements[i].text.contains('@')) {
            priceAfterSeparator = true;
            break;
          }
        }

        // If "à" is in preceding elements, this is the unit price (keep it)
        // If "à" is NOT in preceding elements but in the name, this might be line total (check further)
        if (!priceAfterSeparator && priceElement.followingElements.isNotEmpty) {
          // This price has more elements after it (likely currency + line total), skip it
          print('  ❌ Skipped (European à format - line total): "$itemName"');
          continue;
        }
      }

      // Extract quantity from item name
      int quantity = 1;
      final quantityMatch = _quantityPattern.firstMatch(itemName);
      if (quantityMatch != null) {
        quantity = int.tryParse(
              quantityMatch.group(1) ?? quantityMatch.group(2) ?? quantityMatch.group(3) ?? '1',
            ) ??
            1;
      }

      // Clean item name (remove quantity markers, special chars)
      itemName = _cleanItemName(itemName);

      // Improvement #3: Aggressive item name validation
      // Skip if name is just numbers or symbols
      if (RegExp(r'^[\d\s\.\,\-\*]+$').hasMatch(itemName)) {
        print('  ❌ Skipped (numeric only): "$itemName"');
        continue;  // Skip numeric-only names (OCR artifacts)
      }

      // Improvement #3: Skip if name is too short after cleaning (minimum 3 chars)
      final cleanedNameLength = itemName.replaceAll(RegExp(r'[^\w]'), '').length;
      if (cleanedNameLength < 3) {
        print('  ❌ Skipped (too short after cleaning): "$itemName" (length: $cleanedNameLength)');
        continue;  // Skip very short names (likely OCR noise)
      }

      // Final validation: skip if cleaned name is still too short
      if (itemName.length < 2) {
        print('  ❌ Skipped (final validation): "$itemName" (length: ${itemName.length})');
        continue;
      }

      items.add(
        ParsedItem(
          name: itemName,
          quantity: quantity,
          price: priceElement.price,
          rawLine: priceElement.line.text,
        ),
      );
      print('  ✅ Added item: "$itemName" x$quantity @ ${priceElement.price}');
    }

    print('  - Final items count: ${items.length}');
    if (items.isEmpty) {
      print('  ⚠️ WARNING: All items were filtered out!');
    }

    return items;
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
    // Check for European format first (à pattern for unit price)
    final europeanMatch = _europeanPattern.firstMatch(line);
    if (europeanMatch != null) {
      final priceStr = europeanMatch.group(1) ?? '0.00';
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

      // Extract item name (everything before 'à')
      String name = line.substring(0, europeanMatch.start).trim();

      // Remove quantity notation from name (both at start and end)
      name = name
          .replaceAll(RegExp(r'^\d+\s*[x×X]\s*'), '')  // 2x at start
          .replaceAll(RegExp(r'^[x×X]\s*\d+\s*'), '')  // x2 at start
          .replaceAll(RegExp(r'^\d+\s*@\s*'), '')      // 2@ at start
          .replaceAll(RegExp(r'\s*\d+\s*[x×X]\s*$'), '')  // at end
          .replaceAll(RegExp(r'\s*[x×X]\s*\d+\s*$'), '')  // at end
          .replaceAll(RegExp(r'\s*@\s*\d+\s*$'), '')  // at end
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

    // Fall back to existing logic for non-European formats (RM, USD, etc.)
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

  /// Validate that a price string has valid format (2 decimal places or currency marker)
  static bool _isValidPrice(String priceStr) {
    return priceStr.contains('CHF') ||
        priceStr.contains('EUR') ||
        priceStr.contains('€') ||
        priceStr.contains('USD') ||
        priceStr.contains('\$') ||
        priceStr.contains('GBP') ||
        priceStr.contains('£') ||
        priceStr.contains('RM') ||
        priceStr.contains('MYR') ||
        priceStr.startsWith('.') ||
        (priceStr.contains('.') && priceStr.split('.').last.length == 2) ||
        (priceStr.contains(',') && priceStr.split(',').last.length == 2);
  }

  /// Check if text is just a currency code
  static bool _isCurrencyCode(String text) {
    final upperText = text.toUpperCase().trim();
    return upperText == 'CHF' ||
        upperText == 'EUR' ||
        upperText == 'USD' ||
        upperText == 'GBP' ||
        upperText == 'RM' ||
        upperText == 'MYR' ||
        upperText == 'A' ||  // Sometimes OCR reads "à" as "A"
        upperText.length <= 1;
  }

  /// Extract totals from full text using line-based approach (used for both string and RecognizedText)
  /// Improvement #4: Uses context-aware total price pattern first before falling back to line-based approach
  static Map<String, double> _extractTotalsFromText(String fullText) {
    final totals = <String, double>{};

    // Improvement #4: Try context-aware total pattern first (e.g., "Total: 50.99")
    final totalMatch = _totalPricePattern.firstMatch(fullText);
    if (totalMatch != null) {
      final priceStr = totalMatch.group(2) ?? '0.00';
      final price = _parsePrice(priceStr);
      if (price > 0) {
        totals['total'] = price;
      }
    }

    // Fall back to line-based extraction for other totals (subtotal, tax, etc.)
    final lines = _cleanAndSplitText(fullText);
    final lineTotals = _extractTotals(lines);

    // Merge results, preferring context-aware extraction for 'total'
    for (final entry in lineTotals.entries) {
      if (!totals.containsKey(entry.key)) {
        totals[entry.key] = entry.value;
      }
    }

    return totals;
  }

  /// Clean up item names: remove common OCR artifacts
  static String _cleanItemName(String name) {
    // Remove leading/trailing special characters
    name = name.replaceAll(RegExp(r'^[\s\*\-\.]+'), '');
    name = name.replaceAll(RegExp(r'[\s\*\-\.]+$'), '');

    // Remove European format markers (à only, not regular 'a')
    name = name.replaceAll(RegExp(r'[à@]'), '').trim();

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
  final String rawText;
  final List<String> errors;

  const ParsedReceipt({
    required this.items,
    required this.subtotal,
    required this.total,
    required this.sst,
    required this.serviceCharge,
    required this.rounding,
    this.rawLines = const [],
    this.rawText = '',
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

/// Internal class for element-based price extraction
class _PriceElement {
  final double price;
  final int elementIndex;
  final TextLine line;
  final TextBlock block;
  final int lineIndexInBlock;
  final TextElement element;
  final List<TextElement> precedingElements;
  final List<TextElement> followingElements;

  _PriceElement({
    required this.price,
    required this.elementIndex,
    required this.line,
    required this.block,
    required this.lineIndexInBlock,
    required this.element,
    required this.precedingElements,
    required this.followingElements,
  });
}
