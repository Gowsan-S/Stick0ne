import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stick0ne/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture screen test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Set mobile device screen size (iPhone 16 Pro: 393 x 852, 3.0 ratio)
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const Stick0neApp());
    await tester.pumpAndSettle();

    final element = find.byType(Stick0neApp).evaluate().first;
    final boundary = element.renderObject as RenderRepaintBoundary?;

    expect(boundary, isNotNull);

    await tester.runAsync(() async {
      final image = await boundary!.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        Directory('screenshots').createSync(recursive: true);
        File('screenshots/test_capture.png').writeAsBytesSync(byteData.buffer.asUint8List());
      }
    });

    expect(File('screenshots/test_capture.png').existsSync(), isTrue);
  });
}
