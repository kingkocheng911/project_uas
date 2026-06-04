import 'package:flutter_test/flutter_test.dart';

import 'package:project_uas/app.dart';

void main() {
  testWidgets('KDMP home shell renders main navigation', (tester) async {
    await tester.pumpWidget(const KdmpApp());
    await tester.pumpAndSettle();

    expect(find.text('KDMP'), findsOneWidget);
    expect(find.text('Search products or cooperatives'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });
}
