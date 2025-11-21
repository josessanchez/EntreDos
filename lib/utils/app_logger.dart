import 'package:logger/logger.dart';

// Central logger for the app. Use `appLogger.i(...)`, `appLogger.e(...)`, etc.
final Logger appLogger = Logger(printer: PrettyPrinter(methodCount: 0));
