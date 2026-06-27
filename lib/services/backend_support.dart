import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

class AppLogger {
  const AppLogger._();

  static void info(String scope, String message) {
    developer.log(message, name: scope);
  }

  static void error(
    String scope,
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?>? extra,
  }) {
    final extraText = extra == null || extra.isEmpty
        ? ''
        : ' | extra: ${extra.toString()}';
    developer.log(
      'ERROR: $error$extraText',
      name: scope,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Future<T> runBackendAction<T>(
  String scope,
  Future<T> Function() action, {
  bool retryOnce = false,
}) async {
  try {
    return await action();
  } on PostgrestException catch (error, stackTrace) {
    AppLogger.error(scope, error, stackTrace: stackTrace);
    if (retryOnce && _canRetry(error)) {
      AppLogger.info(scope, 'Retrying once after PostgrestException.');
      return action();
    }
    rethrow;
  } catch (error, stackTrace) {
    AppLogger.error(scope, error, stackTrace: stackTrace);
    rethrow;
  }
}

String friendlyBackendMessage(
  Object error, {
  String fallback = 'Operasi tidak dapat diproses saat ini.',
}) {
  if (error is PostgrestException) {
    final message = error.message.trim();
    return message.isEmpty ? fallback : message;
  }
  final message = error.toString().replaceFirst('Exception: ', '').trim();
  return message.isEmpty ? fallback : message;
}

bool _canRetry(PostgrestException error) {
  final code = error.code?.trim() ?? '';
  final message = error.message.toLowerCase();
  return code == '57014' ||
      message.contains('timeout') ||
      message.contains('timed out') ||
      message.contains('connection');
}
