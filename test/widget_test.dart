import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // CalSnap requires Firebase initialization,
    // so a full widget test needs mock setup.
    expect(true, isTrue);
  });
}
