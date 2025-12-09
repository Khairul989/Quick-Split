import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Abstract interface for OCR service
abstract class OcrService {
  Future<String> recognizeText(String imagePath);
  Future<void> dispose();
}

/// Google ML Kit implementation of OCR service
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

/// Exception thrown during OCR processing
class OcrException implements Exception {
  final String message;

  OcrException(this.message);

  @override
  String toString() => message;
}
