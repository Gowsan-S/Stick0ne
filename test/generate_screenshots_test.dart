import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stick0ne/data/default_stickers.dart';
import 'package:stick0ne/providers/canvas_provider.dart';
import 'package:stick0ne/providers/sticker_provider.dart';
import 'package:stick0ne/screens/main_navigation_screen.dart';
import 'package:stick0ne/screens/preview_display_modal.dart';
import 'package:provider/provider.dart';

Future<void> _loadTestFonts() async {
  try {
    // CupertinoIcons
    final cupertinoFile = File(
      r'C:\Users\Lenovo\AppData\Local\Pub\Cache\hosted\pub.dev\cupertino_icons-1.0.9\assets\CupertinoIcons.ttf',
    );
    if (cupertinoFile.existsSync()) {
      final cupertinoLoader = FontLoader('packages/cupertino_icons/CupertinoIcons');
      cupertinoLoader.addFont(Future.value(ByteData.view(cupertinoFile.readAsBytesSync().buffer)));
      await cupertinoLoader.load();
    }

    // MaterialIcons
    final materialFile = File(
      r'C:\src\flutter_windows_3.47.7-stable\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
    );
    if (materialFile.existsSync()) {
      final materialLoader = FontLoader('MaterialIcons');
      materialLoader.addFont(Future.value(ByteData.view(materialFile.readAsBytesSync().buffer)));
      await materialLoader.load();
    }

    // Chakra Petch Regular, Bold, SemiBold for cyber-geometric logo-matched typography
    final chakraRegular = File('assets/fonts/ChakraPetch-Regular.ttf');
    if (chakraRegular.existsSync()) {
      final chakraLoader = FontLoader('ChakraPetch');
      chakraLoader.addFont(Future.value(ByteData.view(chakraRegular.readAsBytesSync().buffer)));
      final chakraBold = File('assets/fonts/ChakraPetch-Bold.ttf');
      if (chakraBold.existsSync()) {
        chakraLoader.addFont(Future.value(ByteData.view(chakraBold.readAsBytesSync().buffer)));
      }
      final chakraSemiBold = File('assets/fonts/ChakraPetch-SemiBold.ttf');
      if (chakraSemiBold.existsSync()) {
        chakraLoader.addFont(Future.value(ByteData.view(chakraSemiBold.readAsBytesSync().buffer)));
      }
      final chakraMedium = File('assets/fonts/ChakraPetch-Medium.ttf');
      if (chakraMedium.existsSync()) {
        chakraLoader.addFont(Future.value(ByteData.view(chakraMedium.readAsBytesSync().buffer)));
      }
      await chakraLoader.load();
    }
  } catch (e) {
    debugPrint('Font load error: $e');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadTestFonts();
  });

  testWidgets('Generate Stick0ne iOS Black & White Screenshots', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Standard iPhone 16 Pro dimensions (393 x 852 logical, 3.0 ratio)
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final stickerProvider = StickerProvider();
    final canvasProvider = CanvasProvider();

    final screenKey = GlobalKey();

    Widget buildTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: stickerProvider),
          ChangeNotifierProvider.value(value: canvasProvider),
        ],
        child: MaterialApp(
          title: 'Stick0ne',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            fontFamily: 'ChakraPetch',
            scaffoldBackgroundColor: const Color(0xFF000000),
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              secondary: Color(0xFF8E8E93),
              surface: Color(0xFF1C1C1E),
            ),
          ),
          home: RepaintBoundary(
            key: screenKey,
            child: child,
          ),
        ),
      );
    }

    Future<void> saveScreenshot(String name) async {
      await tester.runAsync(() async {
        final boundary = screenKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 1.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final bytes = byteData.buffer.asUint8List();

            // Local project screenshots folder
            final localDir = Directory('screenshots');
            if (!localDir.existsSync()) localDir.createSync(recursive: true);
            File('screenshots/$name.png').writeAsBytesSync(bytes);

            // Conversation artifact directory
            const artifactDirPath = r'C:\Users\Lenovo\.gemini\antigravity\brain\5bdf1f54-32c1-4997-bb63-327d082ec749';
            final artifactDir = Directory(artifactDirPath);
            if (!artifactDir.existsSync()) artifactDir.createSync(recursive: true);
            File('$artifactDirPath/$name.png').writeAsBytesSync(bytes);
          }
        }
      });
    }

    // 1. SCREENSHOT 1: Explore / Search Tab
    await tester.pumpWidget(buildTestApp(const MainNavigationScreen()));
    await tester.pumpAndSettle();
    await saveScreenshot('1_explore_screen');

    // 2. SCREENSHOT 2: Setup Canvas with Sticker & Controls
    // Add a minimal sticker to the canvas
    final sampleSticker = DefaultStickers.allStickers.firstWhere(
      (s) => s.id == 'v_mono_star',
      orElse: () => DefaultStickers.allStickers.first,
    );
    canvasProvider.addSticker(sampleSticker);
    canvasProvider.setDesignName('Midnight Minimal');
    canvasProvider.setPreviewOverlay(PreviewOverlayMode.none);

    // Tap Canvas tab (index 2)
    await tester.tap(find.text('Canvas'));
    await tester.pumpAndSettle();
    await saveScreenshot('2_canvas_customizer');

    // 3. SCREENSHOT 3: Setup Canvas with iOS 18 Lock Screen Overlay
    // 3. SCREENSHOT 3: Active "Stuck on Screen" State
    canvasProvider.setOverlayActiveForTest(true);
    await tester.pumpAndSettle();
    await saveScreenshot('3_lockscreen_overlay');
    canvasProvider.setOverlayActiveForTest(false);

    // 4. SCREENSHOT 4: Studio / Create Sticker Tab
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await saveScreenshot('4_create_studio');

    // 5. SCREENSHOT 5: Gallery / My Setups Tab
    // Save sample design
    canvasProvider.saveCurrentDesign();
    await tester.tap(find.text('Setups'));
    await tester.pumpAndSettle();
    await saveScreenshot('5_my_setups');

    // 6. SCREENSHOT 6: Stick to Screen Display Modal (The Screen Overlay Feature!)
    final sampleBytes = File('screenshots/2_canvas_customizer.png').readAsBytesSync();
    await tester.pumpWidget(
      buildTestApp(
        Scaffold(
          backgroundColor: Colors.black,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: PreviewDisplayModal(
              imageBytes: sampleBytes,
              transparentBytes: sampleBytes,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await saveScreenshot('6_stick_to_screen_modal');
  });
}
