import 'package:riverpod/riverpod.dart';
import 'package:quicksplit/features/ocr/domain/services/ocr_service.dart';
import 'package:quicksplit/features/ocr/domain/services/receipt_parser.dart';

// OCR State sealed class
sealed class OcrState {
  const OcrState();
}

class OcrStateInitial extends OcrState {
  const OcrStateInitial();
}

class OcrStateLoading extends OcrState {
  const OcrStateLoading();
}

class OcrStateSuccess extends OcrState {
  final ParsedReceipt parsedReceipt;
  final String rawText;
  final String imagePath;

  const OcrStateSuccess({
    required this.parsedReceipt,
    required this.rawText,
    required this.imagePath,
  });
}

class OcrStateError extends OcrState {
  final String message;
  const OcrStateError(this.message);
}

// OCR State Notifier using Riverpod 3.0 Notifier class
class OcrStateNotifier extends Notifier<OcrState> {
  @override
  OcrState build() => const OcrStateInitial();

  Future<void> processImage(String imagePath) async {
    state = const OcrStateLoading();
    try {
      print('🔍 [OCR] Starting OCR processing for: $imagePath');

      final ocrService = ref.read(ocrServiceProvider);
      final recognizedText = await ocrService.recognizeText(imagePath);

      print('📝 [OCR] Raw text extracted:');
      print('  - Blocks: ${recognizedText.blocks.length}');
      print('  - Lines: ${recognizedText.blocks.fold(0, (sum, block) => sum + block.lines.length)}');
      print('  - Full text:\n${recognizedText.text}');

      final parsedReceipt = ReceiptParser.parseReceiptFromRecognizedText(recognizedText);

      print('✅ [OCR] Parsing complete:');
      print('  - Items found: ${parsedReceipt.items.length}');
      print('  - Total: ${parsedReceipt.total}');
      if (parsedReceipt.items.isEmpty) {
        print('⚠️ [OCR] WARNING: Zero items detected!');
      }

      state = OcrStateSuccess(
        parsedReceipt: parsedReceipt,
        rawText: recognizedText.text,
        imagePath: imagePath,
      );
    } catch (e) {
      print('❌ [OCR] Error: $e');
      state = OcrStateError(e.toString());
    }
  }

  void reset() {
    state = const OcrStateInitial();
  }
}

// Providers
final ocrServiceProvider = Provider<OcrService>((ref) {
  return GoogleMlKitOcrService();
});

final ocrStateProvider = NotifierProvider<OcrStateNotifier, OcrState>(() {
  return OcrStateNotifier();
});
