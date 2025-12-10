import 'dart:io';
import 'package:logger/logger.dart';

class LoggerService {
  static Logger? _instance;

  static Logger get instance {
    _instance ??= _createLogger();
    return _instance!;
  }

  static Logger _createLogger() {
    final isColored = stdout.hasTerminal && stdout.supportsAnsiEscapes;
    final terminalWidth = stdout.hasTerminal ? stdout.terminalColumns : 80;

    return Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: terminalWidth,
        colors: isColored,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.none,
      ),
      output: ConsoleOutput(),
    );
  }
}

final Logger logger = LoggerService.instance;
