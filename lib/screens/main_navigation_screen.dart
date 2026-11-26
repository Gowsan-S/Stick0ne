import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/canvas_provider.dart';
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: isGesturing ? 4 : 16,
                sigmaY: isGesturing ? 4 : 16,
              ),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x40FFFFFF), // Luminous iOS specular glass sheen
                      Color(0x1FFFFFFF), // Frosted optical glass body
                      Color(0x14FFFFFF), // Transparent depth
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                  border: Border.all(
                    color: const Color(0x8CFFFFFF), // 55% white luminous specular rim
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 28,
                      spreadRadius: -2,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Color(0x1AFFFFFF),
                      blurRadius: 2,
                      spreadRadius: 0,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
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
            color: isSelected ? const Color(0xF2FFFFFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: isSelected
                ? Border.all(color: const Color(0x66FFFFFF), width: 0.8)
                : null,
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
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
