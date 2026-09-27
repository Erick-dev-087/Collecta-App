import 'package:collecta/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots to the login gate', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CollectaApp()));
    await tester.pump();
    // The login portal is shown first (signed out by default).
    expect(find.text('Sign In to Portal'), findsWidgets);
  });
}
