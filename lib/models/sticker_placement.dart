import 'dart:convert';
import 'sticker_item.dart';

class StickerPlacement {
  final String id;
  final StickerItem sticker;
  double x; // normalized 0.0 to 1.0 relative to canvas width
  double y; // normalized 0.0 to 1.0 relative to canvas height
  double scale;
  double rotation; // in radians
  double opacity; // 0.0 to 1.0
  bool flipHorizontal;

  StickerPlacement({
    required this.id,
    required this.sticker,
    this.x = 0.5,
    this.y = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.flipHorizontal = false,
  });

  StickerPlacement copyWith({
    String? id,
    StickerItem? sticker,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    double? opacity,
    bool? flipHorizontal,
  }) {
    return StickerPlacement(
      id: id ?? this.id,
      sticker: sticker ?? this.sticker,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sticker': sticker.toMap(),
      'x': x,
      'y': y,
      'scale': scale,
      'rotation': rotation,
      'opacity': opacity,
      'flipHorizontal': flipHorizontal,
    };
  }

  factory StickerPlacement.fromMap(Map<String, dynamic> map) {
    return StickerPlacement(
      id: map['id'] as String,
      sticker: StickerItem.fromMap(map['sticker'] as Map<String, dynamic>),
      x: (map['x'] as num?)?.toDouble() ?? 0.5,
      y: (map['y'] as num?)?.toDouble() ?? 0.5,
      scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      flipHorizontal: map['flipHorizontal'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory StickerPlacement.fromJson(String source) =>
      StickerPlacement.fromMap(json.decode(source) as Map<String, dynamic>);
}
