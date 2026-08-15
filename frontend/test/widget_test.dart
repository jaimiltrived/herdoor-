import 'package:flutter_test/flutter_test.dart';
import 'package:herdoor_app/main.dart';

void main() {
  testWidgets('HerDoor app renders HerDoor brand header', (WidgetTester tester) async {
    await tester.pumpWidget(const HerDoorApp());
    expect(find.text('HerDoor'), findsWidgets);
  });
}
