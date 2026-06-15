import 'package:flutter/material.dart';

class AdsSectionSettings {
  final String id;
  final String position; // 'top', 'middle', 'bottom'
  final String title;
  final bool isVisible;
  final int order;
  final String type; // 'ads' أو 'products' أو 'carousel' أو 'poster'
  final int maxItems; // عدد العناصر المعروضة
  final String? description; // وصف القسم (اختياري)
  final List<String> linkedSectionIds; // أقسام مربوطة بالبوستر
  final String? posterImageUrl; // صورة البوستر

  AdsSectionSettings({
    required this.id,
    required this.position,
    required this.title,
    required this.isVisible,
    required this.order,
    this.type = 'ads',
    this.maxItems = 6,
    this.description,
    this.linkedSectionIds = const [],
    this.posterImageUrl,
  });

  factory AdsSectionSettings.fromMap(Map<String, dynamic> data) {
    return AdsSectionSettings(
      id: data['id'] ?? '',
      position: data['position'] ?? 'middle',
      title: data['title'] ?? '',
      isVisible: data['isVisible'] ?? true,
      order: data['order'] ?? 0,
      type: data['type'] ?? 'ads',
      maxItems: data['maxItems'] ?? 6,
      description: data['description'],
      linkedSectionIds: List<String>.from(data['linkedSectionIds'] ?? []),
      posterImageUrl: data['posterImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'position': position,
      'title': title,
      'isVisible': isVisible,
      'order': order,
      'type': type,
      'maxItems': maxItems,
      'description': description,
      'linkedSectionIds': linkedSectionIds,
      'posterImageUrl': posterImageUrl,
    };
  }

  AdsSectionSettings copyWith({
    String? id,
    String? position,
    String? title,
    bool? isVisible,
    int? order,
    String? type,
    int? maxItems,
    String? description,
    List<String>? linkedSectionIds,
    String? posterImageUrl,
  }) {
    return AdsSectionSettings(
      id: id ?? this.id,
      position: position ?? this.position,
      title: title ?? this.title,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
      type: type ?? this.type,
      maxItems: maxItems ?? this.maxItems,
      description: description ?? this.description,
      linkedSectionIds: linkedSectionIds ?? this.linkedSectionIds,
      posterImageUrl: posterImageUrl ?? this.posterImageUrl,
    );
  }

  static List<AdsSectionSettings> getDefaultSettings() {
    return [
      AdsSectionSettings(
        id: 'top_section',
        position: 'top',
        title: 'عروض مميزة',
        isVisible: true,
        order: 0,
      ),
      AdsSectionSettings(
        id: 'middle_section',
        position: 'middle',
        title: 'عروض خاصة',
        isVisible: true,
        order: 1,
      ),
      AdsSectionSettings(
        id: 'bottom_section',
        position: 'bottom',
        title: 'عروض إضافية',
        isVisible: true,
        order: 2,
      ),
    ];
  }

  // إنشاء قسم جديد
  static AdsSectionSettings createNewSection({
    required String title,
    required String position,
    required int order,
    String type = 'ads',
    int maxItems = 6,
    String? description,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return AdsSectionSettings(
      id: 'section_$timestamp',
      position: position,
      title: title,
      isVisible: true,
      order: order,
      type: type,
      maxItems: maxItems,
      description: description,
    );
  }

  // إنشاء قسم منتجات
  static AdsSectionSettings createProductSection({
    required String title,
    required String position,
    required int order,
    int maxItems = 6,
    String? description,
  }) {
    return createNewSection(
      title: title,
      position: position,
      order: order,
      type: 'products',
      maxItems: maxItems,
      description: description,
    );
  }

  // إنشاء قسم كاروسيل
  static AdsSectionSettings createCarouselSection({
    required String title,
    required int order,
    String? description,
  }) {
    return AdsSectionSettings(
      id: 'carousel_section',
      position: 'top',
      title: title,
      isVisible: true,
      order: order,
      type: 'carousel',
      maxItems: 1,
      description: description,
    );
  }

  // التحقق من نوع القسم
  bool get isAdsSection => type == 'ads';
  bool get isProductsSection => type == 'products';
  bool get isCarouselSection => type == 'carousel';
  bool get isPosterSection => type == 'poster';

  // الحصول على أيقونة القسم
  String get sectionIcon {
    switch (type) {
      case 'products':
        return '🛍️';
      case 'carousel':
        return '🎠';
      case 'poster':
        return '🖼️';
      case 'ads':
      default:
        return '📢';
    }
  }

  // الحصول على أيقونة نوع القسم
  IconData get typeIcon {
    switch (type) {
      case 'products':
        return Icons.shopping_bag;
      case 'carousel':
        return Icons.view_carousel;
      case 'poster':
        return Icons.collections;
      case 'ads':
      default:
        return Icons.campaign;
    }
  }

  // الحصول على وصف نوع القسم
  String get typeDescription {
    switch (type) {
      case 'products':
        return 'قسم منتجات';
      case 'carousel':
        return 'البانر المتحرك';
      case 'poster':
        return 'بوستر جامع';
      case 'ads':
      default:
        return 'قسم إعلانات';
    }
  }

  // إنشاء بوستر جامع
  static AdsSectionSettings createPosterSection({
    required String title,
    required int order,
    required List<String> linkedSectionIds,
    String? posterImageUrl,
    String? description,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return AdsSectionSettings(
      id: 'poster_$timestamp',
      position: 'middle',
      title: title,
      isVisible: true,
      order: order,
      type: 'poster',
      linkedSectionIds: linkedSectionIds,
      posterImageUrl: posterImageUrl,
      description: description,
    );
  }
}
