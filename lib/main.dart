import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // 1. Tambahkan import ini

import 'app.dart';
import 'services/backend_support.dart';

const forceMockAuth = bool.fromEnvironment('FORCE_MOCK_AUTH');
const startAuthenticated = bool.fromEnvironment('START_AUTHENTICATED');

const forceMockAuth = bool.fromEnvironment('FORCE_MOCK_AUTH');
const startAuthenticated = bool.fromEnvironment('START_AUTHENTICATED');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

<<<<<<< HEAD
  // 2. Hilangkan tanda '#' pada URL saat dijalankan di browser/web
  usePathUrlStrategy();
=======
  // URL strategy hanya relevan di web.
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'FlutterError',
      details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('PlatformDispatcher', error, stackTrace: stack);
    return false;
  };
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)

  if (isSupabaseConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }

  runApp(
    const KdmpApp(
      forceMockAuth: forceMockAuth,
      startAuthenticated: startAuthenticated,
    ),
  );
}
