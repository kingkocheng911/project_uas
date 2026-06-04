import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'theme.dart';

class KdmpApp extends StatelessWidget {
  const KdmpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KDMP Digital Cooperative',
      debugShowCheckedModeBanner: false,
      theme: buildKdmpTheme(),
      home: const HomeShell(),
    );
  }
}
