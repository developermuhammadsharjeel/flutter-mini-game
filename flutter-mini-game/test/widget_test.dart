// This is a basic Flutter widget test for the Block Blast game.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Update this import to match your project name in pubspec.yaml
import 'package:block_blast/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BlockBlastApp());

    // Simply verify that a MaterialApp exists
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}