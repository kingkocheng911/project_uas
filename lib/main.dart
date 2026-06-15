import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // 1. Tambahkan import ini

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Hilangkan tanda '#' pada URL saat dijalankan di browser/web
  usePathUrlStrategy();

  if (isSupabaseConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }
  
  runApp(const KdmpApp());
}