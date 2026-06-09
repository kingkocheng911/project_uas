import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'theme.dart';

class KdmpApp extends StatelessWidget {
  const KdmpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MepuPoin',
      debugShowCheckedModeBanner: false,
      theme: buildKdmpTheme(),
      scrollBehavior: const _KdmpScrollBehavior(),
      home: const HomeShell(),
    );
  }
}

class _KdmpScrollBehavior extends MaterialScrollBehavior {
  const _KdmpScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
