import 'package:flutter_test/flutter_test.dart';

import 'package:ark_busters_kids/main.dart';

void main() {
  testWidgets('Hub shows vocabulary mode', (tester) async {
    await tester.pumpWidget(const ArkBustersKidsApp());
    expect(find.textContaining('ボキャブラリー'), findsWidgets);
  });
}
