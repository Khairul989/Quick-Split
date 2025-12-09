# Receipt OCR Extraction - Reference Implementation Analysis

> Comprehensive analysis of reference implementation from `docs/reference/` folder
> Date: 2025-12-09

---

## OVERVIEW

This reference implementation demonstrates a professional receipt OCR extraction system built with Flutter and Google ML Kit. The approach is **element-level focused**, extracting individual text elements from receipts and applying sophisticated regex-based parsing to identify prices, dates, and merchants. The system emphasizes **user-driven validation** where extracted data is presented for manual correction rather than fully automated extraction.

**Key Architectural Pattern**: Extraction → Filtering → Validation → User Correction

---

## FILE-BY-FILE ANALYSIS

### 1. `scan_receipt_page.dart` - Core Extraction Engine

**Purpose**: Main orchestrator for receipt scanning and data extraction. This is the workhorse of the system.

#### OCR Extraction Logic

- Uses `TextRecognizer` from `google_mlkit_text_recognition` package
- Iterates through hierarchical structure: `RecognizedText.blocks` → `TextBlock.lines` → `TextLine.elements` → `TextElement`
- Captures both full text and individual element bounding boxes
- Creates `ReceiptTextRect` objects pairing each text element with its position

#### Key Functions

```dart
void getRecognisedText(XFile image) async {
  final inputImage = InputImage.fromFilePath(image.path);
  final textRecognizer = TextRecognizer();
  recognizedText = await textRecognizer.processImage(inputImage);
  textRecognizer.close(); // Important: clean up resources
}

List<ReceiptTextRect> createTextRects(RecognizedText recognizedText) {
  // Extracts ALL elements with position data
  for (final block in recognizedText.blocks) {
    for (final line in block.lines) {
      for (final element in line.elements) {
        extractedTextRects.add(
          ReceiptTextRect(rect: element.boundingBox, text: element.text)
        );
      }
    }
  }
}
```

#### Parsing Patterns

##### Price Extraction

```dart
final RegExp priceRegex = RegExp(
  r"(RM|MYR)?\s?(\d+(\.\d{2})?|\.\d{2})",
  caseSensitive: false
);
```

**Matches:**
- `RM 50.99`
- `MYR50.99`
- `.99`
- `50.99`

**Extraction Strategy:**

```dart
List<String> extractPrices(RecognizedText recognizedText) {
  // 1. Iterate through all elements
  for (TextBlock block in recognizedText.blocks) {
    for (TextLine line in block.lines) {
      for (TextElement element in line.elements) {
        String text = element.text;
        final RegExpMatch? match = priceRegex.firstMatch(text);
        if (match != null) {
          matches.add(match.group(0)!);
        }
      }
    }
  }

  // 2. Filter for valid prices
  final List<String> validPrices = matches.where((price) =>
    price.contains('MYR') ||
    price.contains('RM') ||
    price.startsWith('.') ||
    (price.contains('.') && price.split('.').last.length == 2)
  ).toList();

  // 3. Sort descending (highest price first = total)
  validPrices.sort((a, b) {
    double aVal = double.parse(a.replaceAll(RegExp(r"[^\d.]"), ""));
    double bVal = double.parse(b.replaceAll(RegExp(r"[^\d.]"), ""));
    return bVal.compareTo(aVal);
  });

  return validPrices;
}
```

##### Total Price Extraction

```dart
final RegExp selectedPriceRegex = RegExp(
  r"(Total|Grand Total|Balance Due|Amount Due|Subtotal|Net Total|Final Total|Order Total|Invoice Total|Total Amount):\s*([+-]?\d{1,3}(?:,?\d{3})*(?:\.\d{2})?)",
  caseSensitive: false
);

double? extractTotalPrice(RecognizedText recognizedText) {
  final RegExpMatch? match = selectedPriceRegex.firstMatch(scannedText);
  if (match != null) {
    return double.parse(match.group(2)!);
  }
  return null;
}
```

##### Date Extraction (Multi-Format Support)

```dart
final List<RegExp> dateRegexes = [
  RegExp(r"\d{1,2}/\d{1,2}/\d{2,4}"),     // 10/03/2023
  RegExp(r"\d{1,2}\.\d{1,2}\.\d{2,4}"),   // 10.03.2023
  RegExp(r"\d{1,2}-\d{1,2}-\d{2,4}"),     // 10-03-2023
  RegExp(r"\d{1,2}\s+\w+\s+\d{4}"),       // 10 March 2023
  RegExp(r"\d{1,2}\w{2}\s+\w+\s+\d{4}"),  // 10th March 2023
];
```

##### Merchant Extraction (Sophisticated Filtering)

```dart
final RegExp merchantRegex = RegExp(
  r"((Merchant|Outlet|Shop|Store):?\s*)?([A-Z][a-z]+(\s+[A-Z][a-z]+)*([\s\-]*[A-Z]?[a-z]*\d*)?)",
  caseSensitive: false
);

List<String> extractMerchants(RecognizedText recognizedText) {
  final List<String> validMerchants = [];

  // Words that indicate actual merchants
  final List<String> possibleMerchantWords = [
    'store', 'sdn bhd', 'enterprise', 'trading', 'co', 'company', 'limited'
  ];

  // Words to exclude (common receipt noise)
  final List<String> invalidWords = [
    'total', 'change', 'amount', 'receipt', 'phone', 'fax', 'gst', 'tax',
    'delivery', 'discount', 'payment', 'visa', 'mastercard', 'scan', ...
  ];

  bool isHeader = true;
  for (TextBlock block in recognizedText.blocks) {
    for (TextLine line in block.lines) {
      final String text = line.text.trim();

      // Header (first line) typically has merchant name
      if (isHeader) {
        final match = merchantRegex.firstMatch(text);
        if (match != null) {
          final String? merchant = match.group(3);
          if (merchant != null && !invalidWords.any((w) =>
              merchant.toLowerCase().contains(w))) {
            validMerchants.insert(0, merchant); // Prioritize header
          }
        }
      } else {
        // Later lines only if they contain merchant indicator words
        if (possibleMerchantWords.any((word) =>
            text.toLowerCase().contains(word))) {
          validMerchants.add(merchant);
        }
      }
      isHeader = false;
    }
  }
  return validMerchants;
}
```

#### Key Data Structures

- `RecognizedText`: Contains full text and `blocks` array
- `TextBlock`: Groups of text by visual region
- `TextLine`: Individual lines within blocks
- `TextElement`: Individual words/tokens with bounding boxes
- `ReceiptTextRect`: Custom wrapper `{rect: Rect, text: String}`

---

### 2. `scanning_test.dart` - Feature Testing/Debugging

**Purpose**: Test harness demonstrating all extraction features simultaneously.

#### Key Additions

**Visual Highlighting**: `getHighlightRects()` - Creates rectangles for detected prices on image

```dart
List<Rect> getHighlightRects(RecognizedText recognizedText) {
  final List<Rect> highlightRects = [];
  for (TextBlock block in recognizedText.blocks) {
    for (TextLine line in block.lines) {
      for (TextElement element in line.elements) {
        if (priceRegex.firstMatch(element.text) != null) {
          Rect rect = Rect.fromLTRB(
            element.boundingBox.left.toDouble(),
            element.boundingBox.top.toDouble(),
            element.boundingBox.right.toDouble(),
            element.boundingBox.bottom.toDouble(),
          );
          highlightRects.add(rect);
        }
      }
    }
  }
  return highlightRects;
}
```

**Text Spans**: `getHighlightedTextSpans()` - Highlights prices in text display

---

### 3. `receipt_highlight_image.dart` - Visual Interactive Verification

**Purpose**: Display receipt image with interactive text selection and highlighting.

#### Visual Extraction Features

- Scales receipt image to fit screen
- Overlays bounding boxes for all detected text elements
- Tap-to-select functionality for manual correction

```dart
List<Widget> _buildDetectedTextRects(BuildContext context, Size imageSize,
    double imageWidth, double imageHeight) {

  // Calculate scaling to fit screen while maintaining aspect ratio
  final double displayWidth = screenWidth * 0.9 - 2 * padding;
  final double displayHeight = screenHeight * 0.8 - 2 * padding;
  final double scale = min(displayWidth / imageSize.width,
                           displayHeight / imageSize.height);

  // Render bounding box for each text element
  for (ReceiptTextRect textRect in widget.extractedTextRects) {
    final rect = textRect.rect;
    rects.add(
      Positioned(
        left: rect.left * scale + padding,
        top: rect.top * scale + padding,
        child: GestureDetector(
          onTapDown: (details) => _showMenu(textRect.text, context, ...),
          child: Container(
            width: rect.width * scale,
            height: rect.height * scale,
            decoration: BoxDecoration(
              color: AppColors.mainColor2.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
```

#### Context-Aware Menu (Android)

```dart
PopupMenuItem(
  child: const Text('Merchant'),
  onTap: () => merchantController.text = text,
),
PopupMenuItem(
  child: const Text('Total'),
  onTap: () {
    String extractedNumber = '';
    bool hasDecimal = false;
    for (int i = 0; i < text.length; i++) {
      if (text[i] == '.' && !hasDecimal) {
        extractedNumber += '.';
        hasDecimal = true;
      } else if (RegExp(r'\d').hasMatch(text[i])) {
        extractedNumber += text[i];
      }
    }
    priceController.text = extractedNumber;
  },
),
```

---

### 4. `add_receipt_transaction.dart` - Complete Transaction Flow

**Purpose**: Full transaction submission with receipt validation and editing.

#### Number Extraction Pattern

```dart
// From "RM 50.99" or "100.65" → Extract only numbers and one decimal
String extractedNumber = '';
bool hasDecimal = false;
for (int i = 0; i < selectedPrice!.length; i++) {
  if (selectedPrice![i] == '.' && !hasDecimal) {
    extractedNumber += '.';
    hasDecimal = true;
  } else if (RegExp(r'\d').hasMatch(selectedPrice![i])) {
    extractedNumber += selectedPrice![i];
  }
}
priceController.text = extractedNumber;
```

#### Date Parsing

```dart
void extractAndSetDate(String text) {
  final RegExp dateRegExp = RegExp(
    r'(?:(\d{1,2})[\/.-](\d{1,2})[\/.-](\d{2}(?:\d{2})?))' // dd/mm/yy(yy)
  );
  final match = dateRegExp.firstMatch(text);

  if (match != null) {
    int day = int.parse(match.group(1)!);
    int month = int.parse(match.group(2)!);
    int year = int.parse(match.group(3)!);

    // Convert 2-digit year to 4-digit
    if (year < 100) {
      year += (year < 50 ? 2000 : 1900);
    }

    setState(() => selectedDate = DateTime(year, month, day));
  }
}
```

#### Firebase Integration

```dart
Future<bool> addNewReceiptTransaction({
  required String imagePath,
  required RecognizedText recognizedText,
  required List<ReceiptTextRect> extractedTextRects,
  required double amount,
  String? merchant,
  String? note,
  // ... other fields
}) async {
  // 1. Load image and create thumbnail
  final fileAsImage = img.decodeImage(File(imagePath).readAsBytesSync());
  final thumbnail = img.copyResize(fileAsImage,
      height: ImageConstants.imageThumbnailHeight);

  // 2. Upload to Firebase Storage
  final thumbnailRef = FirebaseStorage.instance.ref()
    .child(userId)
    .child('transactions')
    .child('thumbnails')
    .child(fileName);

  // 3. Create transaction document with receipt metadata
  final payload = Transaction(
    transactionId: transactionId,
    userId: userId,
    amount: amount,
    merchant: merchant,
    description: note,
    transactionImage: TransactionImage(
      thumbnailUrl: await thumbnailRef.getDownloadURL(),
      fileUrl: await originalFileRef.getDownloadURL(),
      // ... metadata
    ),
  ).toJson();

  // 4. Save to Firestore
  await FirebaseFirestore.instance
    .collection('transactions')
    .doc(transactionId)
    .set(payload);
}
```

---

### 5. `verify_receipt_details.dart` - Standalone Verification

**Purpose**: Minimal receipt verification interface (simpler than AddReceiptTransaction).

**Features:**
- Pre-fills amount, merchant, date fields with extracted values
- Allows quick edits before saving
- No image highlight mode
- Same extraction logic as `scan_receipt_page.dart`

---

### 6. `transaction_repository.dart` - Data Persistence

**Purpose**: Firestore data layer for receipt transactions.

#### Receipt Data Storage

```dart
class TransactionImage {
  String transactionId;
  String thumbnailUrl;
  String fileUrl;
  String fileName;
  double aspectRatio;
  String thumbnailStorageId;
  String originalFileStorageId;
}

class Transaction {
  String transactionId;
  String userId;
  String walletId;
  double amount;
  DateTime date;
  String? merchant;
  String? description; // note
  TransactionImage? transactionImage;
  List<String> tags;
  bool isBookmark;
}
```

#### Key Methods

- `addNewReceiptTransaction()` - Creates transaction with receipt metadata
- Handles image compression and Firebase storage
- Calculates thumbnail aspect ratio for UI rendering

---

### 7. `scan_receipt.dart` - Basic Scanning

**Purpose**: Simple OCR without extraction logic (mostly scaffolding).

Contains commented-out extraction methods suggesting this is an **early/experimental version** replaced by `scan_receipt_page.dart`.

---

## KEY PATTERNS & TECHNIQUES

### Pattern 1: Hierarchical Element Traversal

```dart
// Most efficient: process OCR hierarchy once
for (TextBlock block in recognizedText.blocks) {
  for (TextLine line in block.lines) {
    for (TextElement element in line.elements) {
      // Process individual elements with position data
    }
  }
}
```

**Benefit**: Access to bounding boxes at element level (word-level precision)

### Pattern 2: Regex Filtering Pipeline

```dart
// 1. Extract raw matches
List<String> allMatches = elements.where(priceRegex.matches).toList();

// 2. Filter for validity
List<String> validPrices = allMatches.where(isValidPrice).toList();

// 3. Sort by relevance
validPrices.sort(byDescendingValue);

return validPrices;
```

### Pattern 3: Context-Aware Extraction

- **Prices**: Sort descending (highest = total)
- **Dates**: Multiple format support (no assumption about locale)
- **Merchants**: Position-aware (header prioritized) + keyword filtering
- **Invalid word filtering**: Excludes common receipt noise

### Pattern 4: Multi-Currency Support

```dart
final RegExp priceRegex = RegExp(
  r"(RM|MYR)?\s?(\d+(\.\d{2})?|\.\d{2})",
  caseSensitive: false
);

// Supports: RM 50.99, MYR 50.99, 50.99 (ambiguous but detected)
```

### Pattern 5: Visual Verification Loop

```
Extract → Display with bounding boxes → User selects/corrects → Save
```

No black-box extraction; user validates every field.

### Pattern 6: Bounding Box Preservation

```dart
// Keep position data throughout pipeline
ReceiptTextRect {
  Rect rect;        // Image coordinates
  String text;      // Extracted text
}
```

Enables visual highlighting and user feedback.

---

## BEST PRACTICES IDENTIFIED

### 1. Element-Level Parsing Over Block-Level

- Word-by-word regex matching is more reliable than block-level text
- Captures spatial relationships precisely
- Enables visual feedback (highlighting)

### 2. Filtering Strategy for Robustness

```dart
// Merchant extraction uses layered filtering:
1. Regex pattern matching
2. Invalid word blacklist (tax, total, payment, etc.)
3. Position-aware logic (header vs. body)
4. Keyword matching (store, company, limited, sdn bhd)
```

### 3. Price Extraction Heuristics

- **Collect all matches** then sort descending
- Highest value = likely total price
- Filter for "valid" prices (has currency symbol OR proper decimal format)

### 4. Date Format Flexibility

- Support 5+ formats without hardcoding locale
- Use optional groups and character alternation
- Don't assume date order (may need locale detection)

### 5. User-Driven Validation

- Extract all possible values
- Present to user for selection/correction
- Never fully automate; always provide override mechanism

### 6. Resource Management

```dart
final textRecognizer = TextRecognizer();
try {
  recognizedText = await textRecognizer.processImage(inputImage);
} finally {
  textRecognizer.close(); // Critical: free ML Kit resources
}
```

### 7. Image Processing Pipeline

```
1. Edge detection (EdgeDetection plugin)
2. Compression (480x640 min, 85% quality JPEG)
3. OCR (Google ML Kit TextRecognizer)
4. Extraction (Regex patterns)
5. Validation (User verification)
6. Storage (Firebase with thumbnail)
```

### 8. Scale-Aware Visual Overlay

```dart
// Always calculate scale factor before rendering overlays
final double scale = min(
  displayWidth / imageSize.width,
  displayHeight / imageSize.height
);

// Apply to all coordinates
left: rect.left * scale + horizontalPadding
```

---

## ADVANCED INSIGHTS

### What Works Well

1. **Multi-pass extraction** - Extract all data types, sort separately
2. **Blacklist filtering** - More maintainable than whitelist for merchants
3. **Position prioritization** - Header text = higher confidence merchant
4. **Decimal validation** - Ensures `.99` format = valid price

### Known Limitations (from code comments)

1. **iOS popup menu not working** - Platform-specific UI bugs
2. **Entity extraction unused** - Commented out (possibly lower accuracy)
3. **Single currency** - MYR/RM hardcoded (not multi-currency ready in some places)
4. **Date parsing ambiguous** - 01/02/2023 could be Jan 2 or Feb 1

### Potential Improvements Evident in Code

1. Support for TikTok/Foodpanda/Shopee orders (merchant list has comments)
2. Item-level extraction attempted but not completed
3. Entity extraction from ML Kit available but disabled

---

## IMPLEMENTATION RECOMMENDATIONS

### For QuickSplit App

Based on this reference implementation, our current QuickSplit OCR implementation should:

1. ✅ **Already using element-level parsing** - Good foundation
2. ✅ **Multi-currency regex patterns** - Already implemented (CHF, EUR, USD, RM)
3. ✅ **3-stage filtering** - Already implemented in receipt_parser.dart
4. ⚠️ **Consider adding visual verification screen** - Like `receipt_highlight_image.dart`
5. ⚠️ **Consider bounding box preservation** - Currently not storing position data
6. ⚠️ **Add merchant extraction** - Not yet implemented
7. ⚠️ **Add date extraction** - Not yet implemented

### Regex Patterns to Consider Adding

```dart
// Total price context-aware extraction
final totalPriceRegex = RegExp(
  r"(Total|Grand Total|Balance Due|Amount Due|Subtotal|Net Total):\s*([+-]?\d{1,3}(?:,?\d{3})*(?:\.\d{2})?)",
  caseSensitive: false
);

// Merchant blacklist for better filtering
final invalidMerchantWords = [
  'total', 'change', 'amount', 'receipt', 'phone', 'fax', 'gst', 'tax',
  'delivery', 'discount', 'payment', 'visa', 'mastercard', 'scan'
];

// Date multi-format support
final dateFormats = [
  RegExp(r"\d{1,2}/\d{1,2}/\d{2,4}"),     // 10/03/2023
  RegExp(r"\d{1,2}\.\d{1,2}\.\d{2,4}"),   // 10.03.2023
  RegExp(r"\d{1,2}-\d{1,2}-\d{2,4}"),     // 10-03-2023
  RegExp(r"\d{1,2}\s+\w+\s+\d{4}"),       // 10 March 2023
];
```

---

## SUMMARY

This reference implementation showcases a **pragmatic, hybrid approach** to receipt OCR:

- Leverages Google ML Kit for text recognition
- Applies sophisticated regex patterns for domain-specific extraction
- Preserves user agency through visual validation
- Maintains spatial data for interactive feedback
- Integrates with Firebase for scalable storage

The system excels at extracting **structured receipt fields** (price, date, merchant) through careful filtering and heuristics, not by attempting fully automated parsing. The emphasis on bounding boxes and visual feedback makes it a **professional-grade receipt capture system** suitable for financial applications.

**Key Takeaway**: The most reliable OCR extraction combines ML-powered text recognition with domain-specific heuristics and mandatory user validation—not black-box automation.
