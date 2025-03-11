import 'package:flutter/material.dart';

enum PromptCategory {
  general,
  writing,
  coding,
  business,
  creative,
  academic,
  personal,
  other
}

enum PromptVisibility { public, private }

class Prompt {
  final String id;
  final String title;
  final String content;
  final PromptCategory category;
  final PromptVisibility visibility;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int usageCount;
  final bool isFavorite;

  Prompt({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.visibility,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.updatedAt,
    this.usageCount = 0,
    this.isFavorite = false,
  });

  Prompt copyWith({
    String? id,
    String? title,
    String? content,
    PromptCategory? category,
    PromptVisibility? visibility,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? usageCount,
    bool? isFavorite,
  }) {
    return Prompt(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      visibility: visibility ?? this.visibility,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      usageCount: usageCount ?? this.usageCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Prompt.empty() {
    return Prompt(
      id: '',
      title: '',
      content: '',
      category: PromptCategory.general,
      visibility: PromptVisibility.private,
      authorId: '',
      authorName: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category.toString().split('.').last,
      'visibility': visibility.toString().split('.').last,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'usageCount': usageCount,
      'isFavorite': isFavorite,
    };
  }

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: _categoryFromString(json['category'] ?? 'general'),
      visibility: _visibilityFromString(json['visibility'] ?? 'private'),
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      usageCount: json['usageCount'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  static PromptCategory _categoryFromString(String category) {
    switch (category) {
      case 'writing':
        return PromptCategory.writing;
      case 'coding':
        return PromptCategory.coding;
      case 'business':
        return PromptCategory.business;
      case 'creative':
        return PromptCategory.creative;
      case 'academic':
        return PromptCategory.academic;
      case 'personal':
        return PromptCategory.personal;
      case 'other':
        return PromptCategory.other;
      default:
        return PromptCategory.general;
    }
  }

  static PromptVisibility _visibilityFromString(String visibility) {
    return visibility == 'public'
        ? PromptVisibility.public
        : PromptVisibility.private;
  }

  static String getCategoryName(PromptCategory category) {
    switch (category) {
      case PromptCategory.general:
        return 'General';
      case PromptCategory.writing:
        return 'Writing';
      case PromptCategory.coding:
        return 'Coding';
      case PromptCategory.business:
        return 'Business';
      case PromptCategory.creative:
        return 'Creative';
      case PromptCategory.academic:
        return 'Academic';
      case PromptCategory.personal:
        return 'Personal';
      case PromptCategory.other:
        return 'Other';
    }
  }

  static IconData getCategoryIcon(PromptCategory category) {
    switch (category) {
      case PromptCategory.general:
        return Icons.all_inclusive;
      case PromptCategory.writing:
        return Icons.edit_note;
      case PromptCategory.coding:
        return Icons.code;
      case PromptCategory.business:
        return Icons.business;
      case PromptCategory.creative:
        return Icons.brush;
      case PromptCategory.academic:
        return Icons.school;
      case PromptCategory.personal:
        return Icons.person;
      case PromptCategory.other:
        return Icons.more_horiz;
    }
  }
}
