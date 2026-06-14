import 'package:flutter_test/flutter_test.dart';
import 'package:sudarshan_mobile/app.dart';

void main() {
  testWidgets('auth gate renders app title', (tester) async {
    await tester.pumpWidget(const SudarshanMobileApp());

    expect(find.text('Sudarshan'), findsOneWidget);
    expect(find.text('Trial Ready'), findsOneWidget);
  });
}
