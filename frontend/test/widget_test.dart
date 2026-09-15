import 'package:flutter_test/flutter_test.dart';

import 'package:the_system/main.dart';

void main() {
  testWidgets('SS Consulting affiche la page de connexion', (WidgetTester tester) async {
    await tester.pumpWidget(const SSConsultingApp());

    expect(find.text('Connexion'), findsOneWidget);
  });
}
