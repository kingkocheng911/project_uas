import 'package:flutter_test/flutter_test.dart';

import 'package:project_uas/app.dart';

void main() {
  testWidgets('MepuPoin home shell renders main navigation', (tester) async {
    await tester.pumpWidget(const KdmpApp(startAuthenticated: true));
    await tester.pumpAndSettle();

    expect(find.text('MepuPoin'), findsOneWidget);
    expect(find.text('Saldo MepuPoin'), findsOneWidget);
    expect(find.text('Isi Saldo'), findsOneWidget);
    expect(find.text('Cari sembako, alat tani, pupuk...'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Akun'), findsWidgets);
  });
}

