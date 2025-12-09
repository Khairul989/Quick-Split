# Phase 2: OCR Pipeline

**Duration:** Week 2
**Status:** Not Started
**Target Completion:** End of Week 2
**Estimated Time:** 18-24 development hours

---

## Overview

Phase 2 implements the complete OCR image capture and receipt parsing pipeline. This is the critical path feature that makes QuickSplit fast—users must capture a receipt and extract all items within 10 seconds. Phase 2 focuses on:

1. Camera integration with real-time preview, focus, and flash control
2. Gallery picker fallback for users who prefer pre-captured images
3. ML Kit text recognition with performance optimization
4. Receipt parsing algorithm that extracts structured items (name, quantity, price)
5. Malaysian receipt handling (RM currency, SST 6%, service charge 10%)
6. Item editing UI for manual corrections
7. Riverpod provider architecture for state management

### Why Phase 2 Matters

- **User Experience:** Successful OCR → fast bill splits. Failed OCR → manual data entry (slow)
- **Parsing Quality:** 85%+ accuracy on Malaysian receipts directly impacts satisfaction
- **Performance:** OCR must complete in <5 seconds on mid-range devices (Xiaomi Redmi Note, iPhone 12)
- **Reliability:** Edge cases (blurry receipts, handwritten notes, multiple currencies) must be handled gracefully

### Success Criteria

All items must be complete before moving to Phase 3:

- [ ] Camera screen with live preview, capture, flash toggle, gallery picker
- [ ] ML Kit text recognition integrated and processing receipts correctly
- [ ] Receipt parsing algorithm extracts items, quantities, prices with 85%+ accuracy
- [ ] Malaysian receipt patterns recognized (RM format, SST, service charge, rounding)
- [ ] Item editor UI allows add/edit/delete operations with real-time totals
- [ ] Hive models (Receipt, ReceiptItem) with TypeAdapters
- [ ] Riverpod providers manage OCR state and item list
- [ ] Loading states implemented (shimmer/skeleton during OCR)
- [ ] Error handling for permissions, OCR failures, parsing errors
- [ ] Unit tests for receipt parser (20+ test cases covering edge cases)
- [ ] Widget tests for camera screen and item editor
- [ ] Complete OCR flow (capture → parse → edit) works end-to-end
- [ ] Static analysis: `flutter analyze` returns no errors
- [ ] Performance: OCR <5s on iPhone 12, <7s on mid-range Android

### Performance Targets

| Operation                             | Target  | Success Metric                                        |
| ------------------------------------- | ------- | ----------------------------------------------------- |
| Camera startup                        | <2s     | Preview shows within 2 seconds of screen navigation   |
| Image capture                         | <1s     | Shutter lag < 1 second                                |
| OCR processing                        | <5s     | Text recognition completes on iPhone 12               |
| Parsing algorithm                     | <500ms  | Receipt parsing <500ms for 50-line receipts           |
| Total flow (capture → editable items) | <10s    | User sees editable items within 10 seconds of capture |
| Memory usage                          | <150 MB | No memory spikes during OCR                           |

---

## Step 1: Camera Integration

### 1.1 Camera Screen Architecture

The camera screen is the entry point for bill capture. It provides:

- Live camera preview with proper aspect ratio
- Capture button with haptic feedback
- Flash toggle (auto/on/off)
- Gallery picker button (fallback option)
- Proper permission handling (Camera, Storage)
- Error states for permission denied, camera unavailable

```dart
// lib/features/scan/presentation/screens/camera_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  late CameraController _cameraController;
  late Future<void> _initializeCameraFuture;
  FlashMode _flashMode = FlashMode.auto;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameraFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available')),
          );
        }
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController.initialize();
      await _cameraController.setFlashMode(_flashMode);

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera initialization error: $e')),
        );
      }
    }
  }

  Future<void> _captureAndProcess() async {
    try {
      if (!_cameraController.value.isInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera not ready')),
        );
        return;
      }

      final image = await _cameraController.takePicture();

      if (mounted) {
        context.pushNamed(
          'ocr_processing',
          extra: {'imagePath': image.path, 'source': 'camera'},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture error: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        context.pushNamed(
          'ocr_processing',
          extra: {'imagePath': pickedFile.path, 'source': 'gallery'},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e')),
        );
      }
    }
  }

  Future<void> _toggleFlash() async {
    try {
      final modes = [FlashMode.auto, FlashMode.on, FlashMode.off];
      final currentIndex = modes.indexOf(_flashMode);
      final nextMode = modes[(currentIndex + 1) % modes.length];

      await _cameraController.setFlashMode(nextMode);

      setState(() {
        _flashMode = nextMode;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flash toggle error: $e')),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isCameraInitialized || !_cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  String _getFlashLabel() {
    switch (_flashMode) {
      case FlashMode.auto:
        return 'Flash: Auto';
      case FlashMode.on:
        return 'Flash: On';
      case FlashMode.off:
        return 'Flash: Off';
      default:
        return 'Flash: Auto';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        elevation: 0,
      ),
      body: FutureBuilder<void>(
        future: _initializeCameraFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (!_isCameraInitialized) {
              return const Center(
                child: Text('Camera initialization failed'),
              );
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_cameraController),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FloatingActionButton(
                            heroTag: 'gallery',
                            onPressed: _pickFromGallery,
                            tooltip: 'Pick from gallery',
                            child: const Icon(Icons.image),
                          ),
                          FloatingActionButton(
                            heroTag: 'capture',
                            onPressed: _captureAndProcess,
                            tooltip: 'Capture receipt',
                            child: const Icon(Icons.camera),
                          ),
                          FloatingActionButton(
                            heroTag: 'flash',
                            onPressed: _toggleFlash,
                            tooltip: _getFlashLabel(),
                            child: Icon(
                              _flashMode == FlashMode.auto
                                  ? Icons.flash_auto
                                  : _flashMode == FlashMode.on
                                      ? Icons.flash_on
                                      : Icons.flash_off,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getFlashLabel(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
```

### 1.2 Camera Permission Handler

Create a permission service for requesting camera and gallery permissions:

```dart
// lib/core/services/permission_service.dart

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestPhotoPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  static Future<Map<Permission, PermissionStatus>> requestBothPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.photos,
    ].request();
    return statuses;
  }

  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  static Future<bool> hasPhotoPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }
}
```

Note: Add `permission_handler: ^11.4.3` to pubspec.yaml and configure platform-specific permissions in AndroidManifest.xml and Info.plist.

---

## Step 2: Gallery Picker Integration

### 2.1 Gallery Picker with Image Preprocessing

The gallery picker is already integrated in the camera screen, but we add preprocessing to optimize images before OCR:

```dart
// lib/features/scan/presentation/screens/gallery_picker_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class GalleryPickerService {
  static const ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndPreprocessImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null;
      }

      return await _preprocessImage(pickedFile.path);
    } catch (e) {
      return null;
    }
  }

  static Future<String> _preprocessImage(String imagePath) async {
    try {
      // Read the image file
      final imageBytes = await File(imagePath).readAsBytes();
      var image = img.decodeImage(imageBytes);

      if (image == null) {
        return imagePath; // Return original if decode fails
      }

      // Resize to optimize for OCR (width 1200px max while maintaining aspect)
      if (image.width > 1200) {
        final aspectRatio = image.height / image.width;
        image = img.copyResize(
          image,
          width: 1200,
          height: (1200 * aspectRatio).toInt(),
          interpolation: img.Interpolation.linear,
        );
      }

      // Save preprocessed image to temp directory
      final tempDir = await getTemporaryDirectory();
      final preprocessedPath =
          '${tempDir.path}/preprocessed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final jpegData = img.encodeJpg(image, quality: 85);
      await File(preprocessedPath).writeAsBytes(jpegData);

      return preprocessedPath;
    } catch (e) {
      // If preprocessing fails, return original image path
      return imagePath;
    }
  }
}
```

---

## Step 3: ML Kit Setup and Integration

### 3.1 OCR Service

Create a comprehensive OCR service that handles text recognition:

```dart
// lib/features/ocr/domain/services/ocr_service.dart

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

abstract class OcrService {
  Future<String> recognizeText(String imagePath);
  Future<void> dispose();
}

class GoogleMlKitOcrService implements OcrService {
  late TextRecognizer _textRecognizer;

  GoogleMlKitOcrService() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  @override
  Future<String> recognizeText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      inputImage.close();

      return recognizedText.text;
    } catch (e) {
      throw OcrException('Text recognition failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}

class OcrException implements Exception {
  final String message;
  OcrException(this.message);

  @override
  String toString() => message;
}
```

### 3.2 Riverpod Provider for OCR Service

```dart
// lib/features/ocr/presentation/providers/ocr_providers.dart

import 'package:riverpod/riverpod.dart';
import '../services/ocr_service.dart';

final ocrServiceProvider = Provider<OcrService>((ref) {
  return GoogleMlKitOcrService();
});

final recognizeTextProvider =
    FutureProvider.family<String, String>((ref, imagePath) async {
  final ocrService = ref.watch(ocrServiceProvider);
  return ocrService.recognizeText(imagePath);
});
```

---

## Step 4: Receipt Parsing Algorithm (CRITICAL)

### 4.1 Parsing Strategy Overview

The receipt parser is the core intelligence of Phase 2. It extracts structured items from raw OCR text by:

1. **Splitting text into lines** and cleaning whitespace
2. **Identifying receipt sections** (header, items, footer with totals)
3. **Detecting item lines** by looking for price patterns (RM XX.XX)
4. **Extracting quantities** (patterns: 2x, x2, @2, etc.)
5. **Recognizing special rows** (Subtotal, Total, SST, Service Charge, Rounding)
6. **Calculating implied prices** and validating totals
7. **Handling edge cases** (missing data, corrupted OCR, multiple currencies)

### 4.2 Receipt Parsing Service (COMPREHENSIVE)

```dart
// lib/features/ocr/domain/services/receipt_parser.dart

import 'package:collection/collection.dart';

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
    r'(subtotal|total|sst|service\s*charge|rounding|discount|tax|gst)',
    caseSensitive: false,
  );

  /// Main entry point: Parse raw OCR text into structured receipt
  static ParsedReceipt parseReceipt(String rawText) {
    if (rawText.trim().isEmpty) {
      return ParsedReceipt(
        items: [],
        subtotal: 0.0,
        total: 0.0,
        sst: 0.0,
        serviceCharge: 0.0,
        rounding: 0.0,
        errors: ['Receipt text is empty'],
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

    final priceStr = priceMatch.group(1) ?? priceMatch.group(0);
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

  ParsedReceipt({
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

  ParsedItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.rawLine,
  });

  double get subtotal => price * quantity;
}
```

### 4.3 Receipt Parser Unit Tests

```dart
// test/features/ocr/services/receipt_parser_test.dart

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

      test('handles OCR artifacts and typos', () {
        const rawText = '''
        Nas! Lemak     RM 12.50
        Teh  A1s       RM 3.00
        ''';

        final receipt = ReceiptParser.parseReceipt(rawText);

        // Should still extract items despite minor typos
        expect(receipt.items.length, equals(2));
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
    });
  });
}
```

---

## Step 5: Data Models with Hive Support

### 5.1 Receipt and ReceiptItem Models

```dart
// lib/features/ocr/domain/models/receipt.dart

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
  String name;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  double price;

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
```

### 5.2 Generate Hive TypeAdapters

Run this command to generate the adapter code:

```bash
cd /Volumes/KhaiSSD/Documents/Github/personal/quicksplit
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates `receipt.g.dart` with Hive type adapters automatically.

---

## Step 6: Item Editor UI

### 6.1 Item Editor Screen

```dart
// lib/features/ocr/presentation/screens/item_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/receipt.dart';

class ItemEditorScreen extends ConsumerStatefulWidget {
  final Receipt receipt;

  const ItemEditorScreen({
    required this.receipt,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends ConsumerState<ItemEditorScreen> {
  late List<ReceiptItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.receipt.items);
  }

  void _addItem() {
    setState(() {
      _items.add(
        ReceiptItem(
          name: 'New Item',
          quantity: 1,
          price: 0.0,
        ),
      );
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, ReceiptItem item) {
    setState(() {
      _items[index] = item;
    });
  }

  void _confirmAndProceed() {
    final updatedReceipt = widget.receipt.copyWith(items: _items);
    Navigator.of(context).pop(updatedReceipt);
  }

  double get _totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Items'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return ItemEditorTile(
                  item: _items[index],
                  onUpdate: (updatedItem) =>
                      _updateItem(index, updatedItem),
                  onDelete: () => _deleteItem(index),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'RM ${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirmAndProceed,
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ItemEditorTile extends StatefulWidget {
  final ReceiptItem item;
  final Function(ReceiptItem) onUpdate;
  final VoidCallback onDelete;

  const ItemEditorTile({
    required this.item,
    required this.onUpdate,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  State<ItemEditorTile> createState() => _ItemEditorTileState();
}

class _ItemEditorTileState extends State<ItemEditorTile> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController =
        TextEditingController(text: widget.item.quantity.toString());
    _priceController =
        TextEditingController(text: widget.item.price.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _notifyUpdate() {
    final updatedItem = ReceiptItem(
      id: widget.item.id,
      name: _nameController.text,
      quantity: int.tryParse(_quantityController.text) ?? 1,
      price: double.tryParse(_priceController.text) ?? 0.0,
    );
    widget.onUpdate(updatedItem);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Item name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _notifyUpdate(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      hintText: 'Qty',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _notifyUpdate(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      hintText: 'Price',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _notifyUpdate(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal: RM ${(int.tryParse(_quantityController.text) ?? 1 * (double.tryParse(_priceController.text) ?? 0.0)).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete item',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Step 7: Riverpod Providers for OCR State

### 7.1 OCR and Item List Providers

```dart
// lib/features/ocr/presentation/providers/item_providers.dart

import 'package:riverpod/riverpod.dart';
import '../../domain/models/receipt.dart';
import '../../domain/services/ocr_service.dart';
import '../../domain/services/receipt_parser.dart';

// State notifier for managing OCR processing state
class OcrStateNotifier extends StateNotifier<OcrState> {
  OcrStateNotifier(this._ocrService)
      : super(const OcrState.initial());

  final OcrService _ocrService;

  Future<void> processImage(String imagePath) async {
    state = const OcrState.loading();
    try {
      final rawText = await _ocrService.recognizeText(imagePath);
      final parsedReceipt = ReceiptParser.parseReceipt(rawText);

      state = OcrState.success(
        parsedReceipt: parsedReceipt,
        rawText: rawText,
        imagePath: imagePath,
      );
    } catch (e) {
      state = OcrState.error(e.toString());
    }
  }

  void reset() {
    state = const OcrState.initial();
  }
}

// State class for OCR
sealed class OcrState {
  const OcrState();

  const factory OcrState.initial() = _InitialState;
  const factory OcrState.loading() = _LoadingState;
  const factory OcrState.success({
    required ParsedReceipt parsedReceipt,
    required String rawText,
    required String imagePath,
  }) = _SuccessState;
  const factory OcrState.error(String message) = _ErrorState;
}

class _InitialState extends OcrState {
  const _InitialState();
}

class _LoadingState extends OcrState {
  const _LoadingState();
}

class _SuccessState extends OcrState {
  final ParsedReceipt parsedReceipt;
  final String rawText;
  final String imagePath;

  const _SuccessState({
    required this.parsedReceipt,
    required this.rawText,
    required this.imagePath,
  });
}

class _ErrorState extends OcrState {
  final String message;

  const _ErrorState(this.message);
}

// Riverpod providers
final ocrServiceProvider = Provider<OcrService>((ref) {
  return GoogleMlKitOcrService();
});

final ocrStateProvider =
    StateNotifierProvider<OcrStateNotifier, OcrState>((ref) {
  final ocrService = ref.watch(ocrServiceProvider);
  return OcrStateNotifier(ocrService);
});

// Item list state notifier
class ItemListNotifier extends StateNotifier<List<ReceiptItem>> {
  ItemListNotifier() : super([]);

  void setItems(List<ReceiptItem> items) {
    state = items;
  }

  void addItem(ReceiptItem item) {
    state = [...state, item];
  }

  void updateItem(int index, ReceiptItem item) {
    final newItems = [...state];
    newItems[index] = item;
    state = newItems;
  }

  void deleteItem(int index) {
    state = state.where((item) => item.id != state[index].id).toList();
  }

  void clear() {
    state = [];
  }
}

final itemListProvider =
    StateNotifierProvider<ItemListNotifier, List<ReceiptItem>>((ref) {
  return ItemListNotifier();
});

// Computed providers
final itemListTotalProvider = Provider<double>((ref) {
  final items = ref.watch(itemListProvider);
  return items.fold(0.0, (sum, item) => sum + item.subtotal);
});
```

---

## Step 8: Complete Code Examples

### 8.1 OCR Processing Screen

```dart
// lib/features/ocr/presentation/screens/ocr_processing_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/item_providers.dart';

class OcrProcessingScreen extends ConsumerWidget {
  final String imagePath;
  final String source;

  const OcrProcessingScreen({
    required this.imagePath,
    required this.source,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrState = ref.watch(ocrStateProvider);

    ref.listen<OcrState>(ocrStateProvider, (previous, next) {
      if (next is _SuccessState) {
        // Set items in the item list provider
        ref.read(itemListProvider.notifier).setItems(
          next.parsedReceipt.items
              .map((item) => ReceiptItem(
                    name: item.name,
                    quantity: item.quantity,
                    price: item.price,
                  ))
              .toList(),
        );

        // Navigate to item editor
        context.pushNamed('item_editor', extra: {
          'parsedReceipt': next.parsedReceipt,
          'imagePath': imagePath,
        });
      } else if (next is _ErrorState) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.message}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Receipt'),
        elevation: 0,
      ),
      body: ocrState.when(
        initial: () {
          // Trigger OCR processing on first build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(ocrStateProvider.notifier).processImage(imagePath);
          });
          return const Center(child: CircularProgressIndicator());
        },
        loading: () => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Extracting text from receipt...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        success: (parsedReceipt, rawText, _) => OcrResultPreview(
          parsedReceipt: parsedReceipt,
          rawText: rawText,
          imagePath: imagePath,
        ),
        error: (message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'OCR Processing Failed',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OcrResultPreview extends StatelessWidget {
  final ParsedReceipt parsedReceipt;
  final String rawText;
  final String imagePath;

  const OcrResultPreview({
    required this.parsedReceipt,
    required this.rawText,
    required this.imagePath,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detected Items',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...parsedReceipt.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(item.name),
                              ),
                              Text('x${item.quantity}'),
                              const SizedBox(width: 8),
                              Text(
                                'RM ${item.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (parsedReceipt.items.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No items detected'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:'),
                        Text(
                          'RM ${parsedReceipt.calculatedTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (parsedReceipt.errors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.orange.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parsing Warnings',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...parsedReceipt.errors
                          .map((error) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.warning,
                                        size: 16, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(error)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back & Retry'),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 8.2 Route Configuration Integration

Add these routes to your router configuration:

```dart
// In lib/core/routing/app_router.dart

GoRoute(
  path: 'ocr-processing',
  name: 'ocr_processing',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return OcrProcessingScreen(
      imagePath: extra['imagePath'] as String,
      source: extra['source'] as String,
    );
  },
),
GoRoute(
  path: 'item-editor',
  name: 'item_editor',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return ItemEditorScreen(
      receipt: extra['receipt'] as Receipt,
    );
  },
),
```

---

## Step 9: Testing Strategy

### 9.1 Receipt Parser Unit Tests (covered in Step 4.3)

Run tests with:

```bash
flutter test test/features/ocr/services/receipt_parser_test.dart
```

### 9.2 Widget Tests for Camera Screen

```dart
// test/features/scan/screens/camera_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('CameraScreen', () {
    testWidgets('displays camera preview when initialized',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScreen(),
        ),
      );

      // Wait for camera initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify camera preview is shown or loading indicator
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
      );
    });

    testWidgets('has capture, gallery, and flash buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera), findsOneWidget);
      expect(find.byIcon(Icons.image), findsOneWidget);
      expect(find.byIcon(Icons.flash_auto), findsOneWidget);
    });
  });
}
```

---

## Step 10: Verification Checklist

Use this checklist to validate Phase 2 completion:

**Camera & Image Capture**

- [ ] Camera screen launches without permission errors
- [ ] Live preview displays in real-time
- [ ] Capture button saves image to app temp directory
- [ ] Gallery picker opens and returns selected image
- [ ] Flash toggle cycles through Auto → On → Off
- [ ] Camera lifecycle properly managed (pause on app background, resume on foreground)
- [ ] Error message shows when camera unavailable

**ML Kit Integration**

- [ ] google_mlkit_text_recognition ^0.15.0 compiles
- [ ] OCR processes images within 5 seconds (iPhone 12+)
- [ ] OCR handles blurry images (outputs something, not crash)
- [ ] Memory usage stays <150 MB during OCR
- [ ] Text recognition works for printed receipts (>85% accuracy)

**Receipt Parsing**

- [ ] Parser extracts items, quantities, prices correctly
- [ ] Malaysian currency format recognized (RM, commas)
- [ ] SST 6% detected and extracted
- [ ] Service charge (10%) detected
- [ ] Quantity patterns recognized (2x, x2, @2)
- [ ] Multi-word item names preserved
- [ ] Total validation catches major discrepancies
- [ ] Parser gracefully handles corrupted OCR output

**Item Editor**

- [ ] Edit screen displays all parsed items
- [ ] Item name, quantity, price are editable
- [ ] Add item button creates new entry
- [ ] Delete button removes item with confirmation
- [ ] Real-time total updates as items change
- [ ] Changes persist when navigating back
- [ ] Validation prevents negative prices/quantities

**Data Models & Persistence**

- [ ] Receipt and ReceiptItem Hive models compile
- [ ] TypeAdapters generated (receipt.g.dart)
- [ ] Receipts can be saved to Hive box
- [ ] Saved receipts can be retrieved
- [ ] JSON serialization works (for future API)

**State Management**

- [ ] OcrStateNotifier correctly transitions between states
- [ ] ItemListNotifier tracks list changes
- [ ] Riverpod providers injectable for testing
- [ ] Provider disposal doesn't leak resources
- [ ] Navigation passes state correctly via extra

**Error Handling**

- [ ] Permission denied → show explanation dialog
- [ ] Camera unavailable → friendly error message
- [ ] OCR failure → show retry button
- [ ] Parsing errors logged but don't crash app
- [ ] No unhandled exceptions in logs

**Performance**

- [ ] Camera startup <2 seconds
- [ ] Image capture <1 second
- [ ] OCR processing <5 seconds (iPhone 12)
- [ ] Parser <500ms for 50-line receipt
- [ ] No jank during item editing (60 FPS)

**Code Quality**

- [ ] `flutter analyze` returns no errors
- [ ] `flutter format` applied to all files
- [ ] No TODOs or FIXMEs
- [ ] Proper null safety (no force unwraps)
- [ ] Constants extracted (no magic numbers)

---

## Common Issues & Troubleshooting

### Issue: Camera preview doesn't show

**Solution:** Ensure camera permissions are granted. Add to AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

And Info.plist (iOS):

```xml
<key>NSCameraUsageDescription</key>
<string>QuickSplit needs camera access to scan receipts</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>QuickSplit needs gallery access to select receipt photos</string>
```

### Issue: OCR takes >5 seconds

**Solution:**

1. Resize image before OCR (max 1200px width)
2. Use `google_mlkit_text_recognition` with `TextRecognitionScript.latin` (default)
3. Test on physical device (emulators are slow)
4. Consider threading OCR on isolate for large images

### Issue: Parser extracts prices but no item names

**Solution:** Review OCR output to check if text recognition failed. Fuzzy receipts may need manual correction. Show raw OCR text for user verification.

### Issue: Service charge/SST not detected

**Solution:** Parser looks for exact keywords ("sst", "service"). If receipt uses different language (Chinese, Tamil), add additional regex patterns.

### Issue: Hive TypeAdapter not generated

**Solution:** Run `flutter pub run build_runner build --delete-conflicting-outputs`. Ensure Hive annotations are correct (typeId must be unique).

---

## Performance Targets Summary

| Metric                   | Target  | Actual (Measure After) |
| ------------------------ | ------- | ---------------------- |
| Camera startup           | <2s     | \_\_                   |
| Image capture            | <1s     | \_\_                   |
| OCR (ML Kit)             | <5s     | \_\_                   |
| Parser (50-line receipt) | <500ms  | \_\_                   |
| Total flow               | <10s    | \_\_                   |
| Memory peak              | <150 MB | \_\_                   |

---

## Next Steps: Phase 3 Preview

Phase 3 will implement the **Assignment Engine**:

1. **People Management** - Add/remove group members
2. **Item Assignment** - Tap items to assign to people
3. **Split Calculator** - Calculate individual shares with tax split
4. **History Storage** - Save past splits with Hive
5. **Quick Groups** - Save frequent groups for reuse

The item list from Phase 2 becomes the input for Phase 3's assignment flow.

---

## Resources & References

- [Google ML Kit Text Recognition Documentation](https://developers.google.com/ml-kit/vision/text-recognition)
- [Flutter Camera Plugin Docs](https://pub.dev/packages/camera)
- [Image Picker Documentation](https://pub.dev/packages/image_picker)
- [Riverpod Official Docs](https://riverpod.dev)
- [Hive Local Storage Guide](https://docs.hivedb.dev/)

---

**Phase 2 Estimated Completion:** 18-24 hours of focused development

Good luck with implementation! The receipt parser is the heart of QuickSplit—spend extra time testing edge cases.
