import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthMockup UI loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const CurrenSeeApp() as Widget);

    // Check App Title
    expect(find.text('CurrenSee'), findsOneWidget);

    //  Check subtitle tagline
    expect(
      find.textContaining('Your trusted currency companion'),
      findsOneWidget,
    );

    //  Check Buttons
    expect(find.text('Sign in with Email'), findsOneWidget);
    expect(find.text('Create an Account'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    // Check footer
    expect(find.text('Powered by ABC Finance Ltd.'), findsOneWidget);
  });
}

class CurrenSeeApp {
  const CurrenSeeApp();
}
