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
      final ocrService = ref.read(ocrServiceProvider);
      final rawText = await ocrService.recognizeText(imagePath);
      final parsedReceipt = ReceiptParser.parseReceipt(rawText);

      state = OcrStateSuccess(
        parsedReceipt: parsedReceipt,
        rawText: rawText,
        imagePath: imagePath,
      );
    } catch (e) {
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
