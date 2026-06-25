import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:veloura/main.dart';

void main() {
  setUpAll(() async {
    Hive.init('/tmp/veloura_test_hive');
  });

  testWidgets('VelouraApp renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: VelouraApp()),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
