import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/canvas_provider.dart';
import '../widgets/ios_glass_capsule.dart';
import 'my_designs_screen.dart';
import 'sticker_creator_screen.dart';
import 'sticker_placement_screen.dart';
import 'sticker_search_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _navigateToCanvas() {
    setState(() {
      _currentIndex = 2; // Placement Canvas tab
    });
    HapticFeedback.selectionClick();
  }

  void _navigateToSearch() {
    setState(() {
      _currentIndex = 0; // Search tab
    });
    HapticFeedback.selectionClick();
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      StickerSearchScreen(onNavigateToCanvas: _navigateToCanvas),
      StickerCreatorScreen(onNavigateToCanvas: _navigateToCanvas),
      StickerPlacementScreen(onNavigateToSearch: _navigateToSearch),
      MyDesignsScreen(onNavigateToCanvas: _navigateToCanvas),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true, // Allows content to show behind frosted floating bar
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildFloatingIosTabBar(context),
    );
  }

  Widget _buildFloatingIosTabBar(BuildContext context) {
    final canvas = context.watch<CanvasProvider>();
    final isGesturing = _currentIndex == 2 && canvas.isGesturing;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isGesturing ? 0.18 : 1.0,
          child: IosGlassCapsule(
            height: 62,
            radius: 31,
            blurSigma: isGesturing ? 6 : 26,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(
              children: [
                _buildTabItem(0, CupertinoIcons.search, 'Explore'),
                _buildTabItem(1, CupertinoIcons.wand_stars, 'Create'),
                _buildTabItem(2, CupertinoIcons.device_phone_portrait, 'Canvas'),
                _buildTabItem(3, CupertinoIcons.square_grid_2x2, 'Setups'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFECECEC),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(25),
            border: isSelected
                ? Border.all(color: Colors.white, width: 1.0)
                : null,
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Color(0x33FFFFFF),
                      blurRadius: 3,
                      offset: Offset(0, -1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.black : const Color(0xB3FFFFFF),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.black : const Color(0xB3FFFFFF),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
