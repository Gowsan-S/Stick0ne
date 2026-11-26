import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stick0ne/main.dart';
import 'package:stick0ne/widgets/stick0ne_logo.dart';
import 'package:stick0ne/providers/canvas_provider.dart';
import 'package:stick0ne/screens/preview_display_modal.dart';
import 'package:stick0ne/screens/sticker_placement_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Stick0ne smoke test - renders search and navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Stick0neApp());
    await tester.pumpAndSettle();

    expect(find.byType(Stick0neLogo), findsWidgets);
    expect(find.text('Explore Stickers'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Canvas'), findsOneWidget);
    expect(find.text('Setups'), findsOneWidget);
  });

  testWidgets('Tapping sticker in Explore directly opens Canvas without modal sheet',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Stick0neApp());
    await tester.pumpAndSettle();

    // Find and tap a sticker in the explore list
    final firstStickerFinder = find.text('Mono Star');
    expect(firstStickerFinder, findsOneWidget);

    await tester.tap(firstStickerFinder);
    await tester.pumpAndSettle();

    // Ensure the intermediate dialog/modal sheet is NOT shown
    expect(find.text('Place on Screen Canvas'), findsNothing);
    expect(find.text('Add to Current Canvas'), findsNothing);

    // Ensure we are immediately on the canvas with transparency control below
    expect(find.text('Transparency'), findsOneWidget);
    expect(find.text('Scale'), findsNothing);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Stick to Screen'), findsOneWidget);
  });

  testWidgets('Clicking Clear button clears stickers from canvas and screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Stick0neApp());
    await tester.pumpAndSettle();

    // 1. Add sticker from explore
    final firstStickerFinder = find.text('Mono Star');
    await tester.tap(firstStickerFinder);
    await tester.pumpAndSettle();

    // 2. We should see the 'Clear' button in top bar
    final clearButton = find.text('Clear');
    expect(clearButton, findsOneWidget);

    // 3. Tap 'Clear' button to trigger dialog
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    // 4. Dialog should show
    expect(find.text('Clear Canvas & Screen?'), findsOneWidget);
    final confirmClear = find.text('Clear All');
    expect(confirmClear, findsOneWidget);

    // 5. Confirm clear
    await tester.tap(confirmClear);
    await tester.pumpAndSettle();

    // 6. Verify canvas is reset to blank canvas
    expect(find.text('Blank Canvas'), findsWidgets);
    expect(find.text('Transparency'), findsNothing);
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('Pure gesture editing: no minimise or maximise buttons, supports scale and rotation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Stick0neApp());
    await tester.pumpAndSettle();

    // 1. Add sticker from explore
    final firstStickerFinder = find.text('Mono Star');
    await tester.tap(firstStickerFinder);
    await tester.pumpAndSettle();

    // 2. Initial scale indicator should show 100%
    expect(find.text('100%'), findsWidgets);

    // 3. Verify NO minimise (-) or maximise (+) button exists on sticker or bottom panel
    expect(find.byIcon(CupertinoIcons.minus), findsNothing);
    expect(find.byIcon(CupertinoIcons.arrow_up_left_arrow_down_right), findsNothing);

    // 4. Test scaling and rotation on the canvas placement
    final canvasProvider = tester.element(find.byType(StickerPlacementScreen)).read<CanvasProvider>();
    final placementId = canvasProvider.selectedPlacementId!;

    // Scaling to 150%
    canvasProvider.updatePlacementScale(placementId, 1.5);
    await tester.pumpAndSettle();
    expect(find.textContaining('150%'), findsWidgets);

    // Rotating by 45 degrees (pi / 4 radians)
    canvasProvider.updatePlacementRotation(placementId, 0.785398);
    await tester.pumpAndSettle();
    expect(find.textContaining('45°'), findsWidgets);
  });

  testWidgets('Create Sticker screen enables Photo option with cutting support',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Stick0neApp());
    await tester.pumpAndSettle();

    // 1. Navigate to Create tab
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Create Sticker'), findsOneWidget);
    expect(find.text('Photo'), findsOneWidget);

    // 2. Select Photo segment
    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();

    expect(find.text('Import Photo for Sticker'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Save & Place Photo Sticker'), findsOneWidget);
  });

  testWidgets('PreviewDisplayModal has no wallpaper or widgets options',
      (WidgetTester tester) async {
    // Valid 1x1 transparent PNG
    final dummyBytes = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CanvasProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PreviewDisplayModal(
              imageBytes: dummyBytes,
              transparentBytes: dummyBytes,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stick to Screen'), findsOneWidget);
    expect(find.text('Wallpaper'), findsNothing);
    expect(find.text('Widgets'), findsNothing);
  });

  testWidgets('Can place N stickers, delete one by one, and delete all',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Stick0neApp());
    await tester.pumpAndSettle();

    // 1. Add first sticker from explore
    await tester.tap(find.text('Mono Star'));
    await tester.pumpAndSettle();
    expect(find.text('Clear'), findsOneWidget);

    // 2. Add second sticker via Add button
    await tester.tap(find.text('Add').first);
    await tester.pumpAndSettle();

    // Select second sticker inside the Add Sticker sheet
    final stickerInSheet = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(stickerInSheet.first);
    await tester.pumpAndSettle();

    // 3. We now have multiple stickers: top bar should show Clear All
    expect(find.textContaining('Clear All'), findsOneWidget);

    // 4. Delete one by one using Delete button
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // 5. 1 sticker remaining
    expect(find.text('Clear'), findsOneWidget);

    // 6. Delete all using Clear
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();

    // Canvas should now be blank
    expect(find.text('Blank Canvas'), findsWidgets);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('Stickers export clean without editing options or selection handles',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Stick0neApp());
    await tester.pumpAndSettle();

    // 1. Add sticker from explore
    await tester.tap(find.text('Mono Star'));
    await tester.pumpAndSettle();

    // 2. While actively editing on canvas, delete button is visible and no resize handle exists
    expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.arrow_up_left_arrow_down_right), findsNothing);

    // 3. When unselected (as happens during export to screen), all editing options are strictly removed
    final canvasProvider = tester.element(find.byType(StickerPlacementScreen)).read<CanvasProvider>();
    canvasProvider.selectPlacement(null);
    await tester.pumpAndSettle();

    // All editing handles and delete buttons are completely gone
    expect(find.byIcon(CupertinoIcons.xmark), findsNothing);
    expect(find.byIcon(CupertinoIcons.arrow_up_left_arrow_down_right), findsNothing);

    // Verify Stick to Screen button is available
    expect(find.text('Stick to Screen'), findsOneWidget);
  });
}
