import 'package:flutter_test/flutter_test.dart';

import 'package:week5_offline_notes/main.dart';

void main() {
  testWidgets('offline-first navigation is displayed', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Posts'), findsOneWidget);
    expect(find.text('Catatan'), findsOneWidget);
    expect(find.text('Pengaturan'), findsOneWidget);
  });
}
