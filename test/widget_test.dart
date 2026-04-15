import 'package:flutter_test/flutter_test.dart';

import 'package:kulup_mobile/features/auth/login_page.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Login page renders required fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(onLoginSuccess: () {}),
      ),
    );

    expect(find.text('Kulup Mobile'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Sifre'), findsOneWidget);
    expect(find.text('Giris yap'), findsOneWidget);
  });
}
