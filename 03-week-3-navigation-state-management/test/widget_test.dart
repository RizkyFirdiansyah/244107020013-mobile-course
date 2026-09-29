import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_navigation/pages/todo_page.dart';

void main() {
  testWidgets('menambah tugas baru', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: TodoPage())),
    );

    await tester.pump();

    expect(find.text('Tidak ada tugas di kategori ini'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));

    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField), 'Kerjakan PR minggu 3');
    await tester.pump();

    await tester.tap(find.text('Tambah'));

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Kerjakan PR minggu 3'), findsOneWidget);
  });
}
