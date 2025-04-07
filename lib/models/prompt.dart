import 'package:flutter/material.dart';

enum PromptCategory {
  business,
  career,
  chatbot,
  coding,
  education,
  fun,
  marketing,
  productivity,
  seo,
  writing,
  other
}

class Prompt {
  final String id;
  final String title;
  final String content;
  final String? description;
  final PromptCategory category;
  final bool isPublic;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String language;
  final bool isFavorite;
  final int usageCount; // This might not be in the API, keeping for UI

  Prompt({
    required this.id,
    required this.title,
    required this.content,
    this.description,
    required this.category,
    required this.isPublic,
    required this.userId,
    required this.userName,
    required this.createdAt,
    required this.updatedAt,
    required this.language,
    this.isFavorite = false,
    this.usageCount = 0,
  });

  Prompt copyWith({
    String? id,
    String? title,
    String? content,
    String? description,
    PromptCategory? category,
    bool? isPublic,
    String? userId,
    String? userName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? language,
    bool? isFavorite,
    int? usageCount,
  }) {
    return Prompt(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      description: description ?? this.description,
      category: category ?? this.category,
      isPublic: isPublic ?? this.isPublic,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      language: language ?? this.language,
      isFavorite: isFavorite ?? this.isFavorite,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  factory Prompt.empty() {
    return Prompt(
      id: '',
      title: '',
      content: '',
      description: '',
      category: PromptCategory.other,
      isPublic: false,
      userId: '',
      userName: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      language: 'English',
    );
  }

  // Update the toJson method to match the API documentation
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'description': description,
      'category': category.toString().split('.').last,
      'isPublic': isPublic,
      'language': language,
      // Only include these fields if they're not empty/null and needed for updates
      if (id.isNotEmpty) 'id': id,
      if (userId.isNotEmpty) 'userId': userId,
      if (userName.isNotEmpty) 'userName': userName,
    };
  }

  factory Prompt.fromJson(Map<String, dynamic> json) {
    // Handle MongoDB-style _id field
    String promptId = '';
    if (json.containsKey('id')) {
      promptId = json['id'] ?? '';
    } else if (json.containsKey('_id')) {
      promptId = json['_id'] ?? '';
    }

    return Prompt(
      id: promptId,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      description: json['description'],
      category: _categoryFromString(json['category'] ?? 'other'),
      isPublic: json['isPublic'] ?? false,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      language: json['language'] ?? 'English',
      isFavorite: json['isFavorite'] ?? false,
      usageCount: 0, // This might not be in the API response
    );
  }

  static PromptCategory _categoryFromString(String category) {
    switch (category) {
      case 'business':
        return PromptCategory.business;
      case 'career':
        return PromptCategory.career;
      case 'chatbot':
        return PromptCategory.chatbot;
      case 'coding':
        return PromptCategory.coding;
      case 'education':
        return PromptCategory.education;
      case 'fun':
        return PromptCategory.fun;
      case 'marketing':
        return PromptCategory.marketing;
      case 'productivity':
        return PromptCategory.productivity;
      case 'seo':
        return PromptCategory.seo;
      case 'writing':
        return PromptCategory.writing;
      default:
        return PromptCategory.other;
    }
  }

  static String getCategoryName(PromptCategory category) {
    switch (category) {
      case PromptCategory.business:
        return 'Business';
      case PromptCategory.career:
        return 'Career';
      case PromptCategory.chatbot:
        return 'Chatbot';
      case PromptCategory.coding:
        return 'Coding';
      case PromptCategory.education:
        return 'Education';
      case PromptCategory.fun:
        return 'Fun';
      case PromptCategory.marketing:
        return 'Marketing';
      case PromptCategory.productivity:
        return 'Productivity';
      case PromptCategory.seo:
        return 'SEO';
      case PromptCategory.writing:
        return 'Writing';
      case PromptCategory.other:
        return 'Other';
    }
  }

  static IconData getCategoryIcon(PromptCategory category) {
    switch (category) {
      case PromptCategory.business:
        return Icons.business;
      case PromptCategory.career:
        return Icons.work;
      case PromptCategory.chatbot:
        return Icons.chat;
      case PromptCategory.coding:
        return Icons.code;
      case PromptCategory.education:
        return Icons.school;
      case PromptCategory.fun:
        return Icons.emoji_emotions;
      case PromptCategory.marketing:
        return Icons.trending_up;
      case PromptCategory.productivity:
        return Icons.schedule;
      case PromptCategory.seo:
        return Icons.search;
      case PromptCategory.writing:
        return Icons.edit_note;
      case PromptCategory.other:
        return Icons.more_horiz;
    }
  }
}
