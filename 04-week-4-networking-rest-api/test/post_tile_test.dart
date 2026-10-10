import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/widgets/post_tile.dart';

void main() {
  testWidgets('PostTile shows post summary and handles taps', (tester) async {
    var tapped = false;
    const post = Post(
      userId: 1,
      id: 7,
      title: 'A post title',
      body: 'A complete post body',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostTile(post: post, onTap: () => tapped = true),
        ),
      ),
    );

    expect(find.text('7'), findsOneWidget);
    expect(find.text('A post title'), findsOneWidget);
    expect(find.text('A complete post body'), findsOneWidget);

    await tester.tap(find.byType(PostTile));
    expect(tapped, isTrue);
  });
}
