import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      bottomNavigationBar: _buildFloatingIosTabBar(),
    );
  }

  Widget _buildFloatingIosTabBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x38FFFFFF), // Liquid glass top refraction highlight
                    Color(0x142C2C2E), // Fluid translucent center (crystal clear view of stickers)
                    Color(0x24000000), // Liquid bottom refraction depth
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                border: Border.all(
                  color: const Color(0x40FFFFFF), // 25% white glossy refraction rim
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D000000),
                    blurRadius: 28,
                    spreadRadius: -4,
                    offset: Offset(0, 10),
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
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
