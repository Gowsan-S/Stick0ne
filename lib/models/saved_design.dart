import 'dart:convert';
import 'sticker_placement.dart';

enum BackgroundType {
  color,
  gradient,
  image,
  transparent,
}

class SavedDesign {
  final String id;
  String name;
  BackgroundType backgroundType;
  int solidColorValue;
  List<int> gradientColorValues;
  double gradientAngle;
  String? bgImagePath;
  List<StickerPlacement> placements;
  String? thumbnailPath;
  DateTime createdAt;
  DateTime updatedAt;

  SavedDesign({
    required this.id,
    required this.name,
    this.backgroundType = BackgroundType.color,
    this.solidColorValue = 0xFF12131C, // aesthetic dark by default
    this.gradientColorValues = const [0xFF1F1C2C, 0xFF928DAB],
    this.gradientAngle = 45.0,
    this.bgImagePath,
    required this.placements,
    this.thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  SavedDesign copyWith({
    String? id,
    String? name,
    BackgroundType? backgroundType,
    int? solidColorValue,
    List<int>? gradientColorValues,
    double? gradientAngle,
    String? bgImagePath,
    List<StickerPlacement>? placements,
    String? thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedDesign(
      id: id ?? this.id,
      name: name ?? this.name,
      backgroundType: backgroundType ?? this.backgroundType,
      solidColorValue: solidColorValue ?? this.solidColorValue,
      gradientColorValues: gradientColorValues ?? this.gradientColorValues,
      gradientAngle: gradientAngle ?? this.gradientAngle,
      bgImagePath: bgImagePath ?? this.bgImagePath,
      placements: placements ?? this.placements,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'backgroundType': backgroundType.name,
      'solidColorValue': solidColorValue,
      'gradientColorValues': gradientColorValues,
      'gradientAngle': gradientAngle,
      'bgImagePath': bgImagePath,
      'placements': placements.map((p) => p.toMap()).toList(),
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SavedDesign.fromMap(Map<String, dynamic> map) {
    return SavedDesign(
      id: map['id'] as String,
      name: map['name'] as String,
      backgroundType: BackgroundType.values.firstWhere(
        (e) => e.name == map['backgroundType'],
        orElse: () => BackgroundType.color,
      ),
      solidColorValue: map['solidColorValue'] as int? ?? 0xFF12131C,
      gradientColorValues: (map['gradientColorValues'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [0xFF1F1C2C, 0xFF928DAB],
      gradientAngle: (map['gradientAngle'] as num?)?.toDouble() ?? 45.0,
      bgImagePath: map['bgImagePath'] as String?,
      placements: (map['placements'] as List<dynamic>?)
              ?.map((p) => StickerPlacement.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      thumbnailPath: map['thumbnailPath'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SavedDesign.fromJson(String source) =>
      SavedDesign.fromMap(json.decode(source) as Map<String, dynamic>);
}
