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
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xCC1A1A1E), // Frosted dark glass
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: const Color(0x33FFFFFF), // Ultra-fine frosted border
                  width: 0.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 20,
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
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.black : const Color(0xFF8E8E93),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.black : const Color(0xFF8E8E93),
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
