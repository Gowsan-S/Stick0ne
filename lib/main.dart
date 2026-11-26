import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/canvas_provider.dart';
import 'providers/sticker_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // iOS-style immersive system overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Lock app orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const Stick0neApp());
}

class Stick0neApp extends StatelessWidget {
  const Stick0neApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StickerProvider()),
        ChangeNotifierProvider(create: (_) => CanvasProvider()),
      ],
      child: MaterialApp(
        title: 'Stick0ne',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF000000), // OLED Pure Black
          canvasColor: const Color(0xFF000000),
          cardColor: const Color(0xFF1C1C1E), // iOS Grouped Inset Card
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFFFFF), // Pure White accent
            onPrimary: Color(0xFF000000), // Pure Black text on white
            secondary: Color(0xFF8E8E93), // iOS Secondary Label
            surface: Color(0xFF121212), // Deep surface
            onSurface: Color(0xFFFFFFFF),
            outline: Color(0x33FFFFFF), // Frosted glass border
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF000000),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          sliderTheme: SliderThemeData(
            activeTrackColor: Colors.white,
            inactiveTrackColor: const Color(0xFF2C2C2E),
            thumbColor: Colors.white,
            overlayColor: const Color(0x33FFFFFF),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF1C1C1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(22)),
            ),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFF1C1C1E),
            modalBackgroundColor: Color(0xFF1C1C1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}
