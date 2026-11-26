import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../providers/canvas_provider.dart';

class PhoneMockupOverlay extends StatelessWidget {
  final PreviewOverlayMode mode;

  const PhoneMockupOverlay({
    super.key,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == PreviewOverlayMode.none) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0x33FFFFFF), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Column(
            children: [
              _buildDynamicIslandHeader(),
              Expanded(
                child: mode == PreviewOverlayMode.homeScreen
                    ? _buildIosHomeScreen()
                    : _buildIosLockScreen(),
              ),
              _buildHomeIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicIslandHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '9:41',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.antenna_radiowaves_left_right, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  const Icon(CupertinoIcons.wifi, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  const Icon(CupertinoIcons.battery_100, color: Colors.white, size: 18),
                ],
              ),
            ],
          ),
          // iOS 18 Dynamic Island Pill
          Container(
            width: 86,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x33FFFFFF), width: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIosHomeScreen() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Monochromatic App Icon Grid (iOS squircle icons)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              return Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xCC1C1C1E),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: const Color(0x33FFFFFF), width: 0.8),
                    ),
                    child: Icon(
                      _getIosMockIcon(index),
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const Spacer(),
        // iOS 18 Search Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x661C1C1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x1AFFFFFF), width: 0.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(CupertinoIcons.search, size: 10, color: Color(0xFF8E8E93)),
              SizedBox(width: 4),
              Text(
                'Search',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // iOS 18 Frosted Dock
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x99242426),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x33FFFFFF), width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDockSquircle(CupertinoIcons.phone_fill),
              _buildDockSquircle(CupertinoIcons.chat_bubble_fill),
              _buildDockSquircle(CupertinoIcons.camera_fill),
              _buildDockSquircle(CupertinoIcons.compass_fill),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDockSquircle(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xCC1C1C1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  IconData _getIosMockIcon(int index) {
    const icons = [
      CupertinoIcons.mail,
      CupertinoIcons.calendar,
      CupertinoIcons.photo,
      CupertinoIcons.music_note,
      CupertinoIcons.map,
      CupertinoIcons.clock,
      CupertinoIcons.gear_alt,
      CupertinoIcons.bag,
    ];
    return icons[index % icons.length];
  }

  Widget _buildIosLockScreen() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Icon(CupertinoIcons.lock_fill, color: Colors.white70, size: 15),
        const SizedBox(height: 6),
        const Text(
          'Wednesday, Nov 26',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        // iOS 18 Bold Modern Clock
        const Text(
          '09:41',
          style: TextStyle(
            color: Colors.white,
            fontSize: 68,
            fontWeight: FontWeight.w700,
            letterSpacing: -2.5,
            height: 1.05,
          ),
        ),
        const Spacer(),
        // iOS 18 Lock Screen Flashlight & Camera shortcut circles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLockScreenAction(CupertinoIcons.lightbulb_fill),
              _buildLockScreenAction(CupertinoIcons.camera_fill),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLockScreenAction(IconData icon) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0x801C1C1E),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x40FFFFFF), width: 0.8),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildHomeIndicator() {
    return Container(
      width: 110,
      height: 4.5,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }
}
