import 'dart:convert';

enum StickerType {
  vector,
  emoji,
  text,
  image,
}

class StickerItem {
  final String id;
  final String title;
  final String category;
  final StickerType type;
  final String data; // vectorId, emoji char, text content, or image file path
  final bool isCustom;
  final List<String> tags;
  final DateTime createdAt;
  final String? secondaryData; // font, color, or metadata

  StickerItem({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.data,
    this.isCustom = false,
    this.tags = const [],
    DateTime? createdAt,
    this.secondaryData,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'type': type.name,
      'data': data,
      'isCustom': isCustom,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'secondaryData': secondaryData,
    };
  }

  factory StickerItem.fromMap(Map<String, dynamic> map) {
    return StickerItem(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      type: StickerType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => StickerType.vector,
      ),
      data: map['data'] as String,
      isCustom: map['isCustom'] as bool? ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      secondaryData: map['secondaryData'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory StickerItem.fromJson(String source) =>
      StickerItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
