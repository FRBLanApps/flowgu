import 'package:flutter_test/flutter_test.dart';
import 'package:flowgu/app/app.dart';

void main() {
  testWidgets('boots the app shell', (tester) async {
    await tester.pumpWidget(const FlowguApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(FlowguApp), findsOneWidget);
  });
}
