# Stick0ne 🎨

> **A minimalist monochrome sticker app for iOS and Android.**  
> Designed with a high-contrast **Black and White theme**, the modern **iOS 18 Human Interface Guidelines (UI/UX)**, and a native **Floating Screen Overlay Engine** so your stickers stick directly onto your phone screen glass without altering your wallpaper.

---

## 📌 Floating Screen Overlay Engine ("Stick to Screen")

1. **Sticks Directly to Screen Glass (Not a Wallpaper Replacement)**
   - Stickers float directly over your launcher, app icons, and games with 100% transparent backdrops.
   - Your personal lock screen and home screen wallpapers remain **100% intact**.
2. **Touch Pass-Through**
   - Configured via Android `WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE` and `FLAG_NOT_FOCUSABLE`.
   - Touches pass directly through the sticker to the underlying apps, launcher icons, and gestures.
3. **In-App Editing Only (Feature 4)**
   - Outside the app, stickers are fixed and non-interactive. Users must open Stick0ne to reposition, adjust opacity, add new stickers, or remove them.
4. **Live On-Screen Status & iOS Support**
   - Live status badge (`LIVE ON DISPLAY`) with 1-tap "Stick to Screen" and "Remove from Screen".
   - On iOS: Apple's strict sandbox prohibits third-party floating overlays; Stick0ne provides **Home Screen & Lock Screen Widgets** (WidgetKit) and Wallpaper Imprinting.

---

## 🖤 Black & White Theme & iOS 18 UI/UX

1. **OLED Pure Black & White Monochromatic Palette**  
   - True OLED Pure Black (`#000000`) background and Apple system grouped card backgrounds (`#1C1C1E`, `#2C2C2E`).
   - High-contrast pure white typography, button capsules, and delicate frosted glass borders (`rgba(255,255,255,0.15)`).
   - Monochromatic sticker categories: *Minimal, Kawaii, Aesthetic, Retro, Cyberpunk, Nature, Typography, Emoji, and My Stickers*.

2. **iOS 18 Floating Island Tab Bar**  
   - Detached frosted glass capsule floating above the bottom with a real-time blur (`BackdropFilter` with `sigma: 25`).
   - Dynamic sliding pill selection with Apple Cupertino SF Symbols (`CupertinoIcons.search`, `CupertinoIcons.wand_stars`, `CupertinoIcons.device_phone_portrait`, `CupertinoIcons.square_grid_2x2`).
   - Tactile haptic feedback (`HapticFeedback.lightImpact()`).

3. **Apple iOS Inset Search & Capsule Filters**  
   - iOS-style search bar with magnifying glass, clear button, and zinc secondary text (`#8E8E93`).
   - Inset pill category filters with white active highlight capsules.

4. **iOS 18 Sliding Segmented Controls**  
   - In the Studio screen, switch seamlessly between **✏️ Doodle**, **💬 Badge**, and **📷 Photo** using Apple's capsule segmented control.
   - Monochromatic sketch palette (White, Silver, Zinc, Slate, Charcoal) and iOS Control Center style sliders.

5. **Blank Setup Canvas & Customization**  
   - Phone canvas with **Dynamic Island** cutout and curved bezel.
   - **Apple Control Center Opacity Slider**: Thick capsule slider with live percentage feedback.
   - **Interactive Overlays**: Toggle real-time iOS 18 Lock Screen (bold clock, date, flashlight & camera circular buttons) and Home Screen (squircle icon grid and frosted dock) overlays to test sticker alignments.
   - **"Float on Screen" Transparent Backdrop**: Lets you preview stickers as floating objects directly on your screen.

6. **iOS Apply / Stick to Screen Modal**  
   - iOS sheet with modal grabber handle (`#48484A`).
   - Segmented navigation: **Screen Overlay** (Stick to Screen), **Wallpaper** (Home/Lock wallpaper pair), and **Widgets**.

---

## 📱 Architecture & Files

```
lib/
├── main.dart                          # Monochromatic theme & system UI overlays
├── data/
│   └── default_stickers.dart          # Built-in sticker catalog including Minimal collection
├── models/
│   ├── sticker_item.dart              # Sticker definition & serialization
│   ├── sticker_placement.dart         # Position (x,y), scale, opacity & rotation
│   └── saved_design.dart              # Persistent setups & gallery data
├── providers/
│   ├── sticker_provider.dart          # Search, category & sticker library state
│   └── canvas_provider.dart           # Active placement, opacity, overlay state
├── services/
│   ├── screen_overlay_service.dart    # Android WindowManager overlay service bridge
│   ├── storage_service.dart           # Local storage & file caching
│   └── wallpaper_service.dart         # Android WallpaperManager & iOS Photo Export
├── screens/
│   ├── main_navigation_screen.dart    # iOS 18 floating glassmorphic tab bar
│   ├── sticker_search_screen.dart     # Apple Large Title & Inset search
│   ├── sticker_creator_screen.dart    # Segmented Doodle / Badge / Photo studio
│   ├── sticker_placement_screen.dart  # Lock screen / Screen overlay canvas customizer
│   ├── preview_display_modal.dart     # iOS Stick to Screen / Wallpaper modal
│   └── my_designs_screen.dart         # iOS Wallpaper gallery & layout management
└── widgets/
    ├── vector_stickers.dart           # Vector and text badge rendering engine
    ├── drawing_canvas.dart            # Freehand drawing studio
    └── phone_mockup_overlay.dart      # iOS 18 Dynamic Island, Lock & Home screens
```

Native Android Code:
- `android/app/src/main/kotlin/com/stick0ne/app/stick0ne/StickerOverlayService.kt`: Background foreground service mounting transparent stickers with `TYPE_APPLICATION_OVERLAY` and `FLAG_NOT_TOUCHABLE`.
- `android/app/src/main/kotlin/com/stick0ne/app/stick0ne/MainActivity.kt`: MethodChannels for `com.stick0ne.app/overlay` and `com.stick0ne.app/wallpaper`.
