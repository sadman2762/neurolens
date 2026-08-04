import 'package:flutter_test/flutter_test.dart';
import 'package:neurolens/app/app.dart';

void main() {
  testWidgets('NeuroLens app renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const NeuroLensApp());

    expect(
      find.text('NeuroLens app structure is working'),
      findsOneWidget,
    );
  });
}