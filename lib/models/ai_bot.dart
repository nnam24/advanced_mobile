class AIBot {
  final String id;
  final String name;
  final String description;
  final String instructions;
  final String avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> knowledgeIds;
  final bool isPublished;
  final Map<String, String> publishedChannels;

  AIBot({
    required this.id,
    required this.name,
    required this.description,
    required this.instructions,
    required this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.knowledgeIds,
    required this.isPublished,
    required this.publishedChannels,
  });

  AIBot copyWith({
    String? id,
    String? name,
    String? description,
    String? instructions,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? knowledgeIds,
    bool? isPublished,
    Map<String, String>? publishedChannels,
  }) {
    return AIBot(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      knowledgeIds: knowledgeIds ?? this.knowledgeIds,
      isPublished: isPublished ?? this.isPublished,
      publishedChannels: publishedChannels ?? this.publishedChannels,
    );
  }

  factory AIBot.empty() {
    return AIBot(
      id: '',
      name: '',
      description: '',
      instructions: 'You are a helpful AI assistant.',
      avatarUrl: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      knowledgeIds: [],
      isPublished: false,
      publishedChannels: {},
    );
  }

  factory AIBot.fromJson(Map<String, dynamic> json) {
    return AIBot(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      instructions: json['instructions'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      knowledgeIds: json['knowledgeIds'] != null 
          ? List<String>.from(json['knowledgeIds']) 
          : [],
      isPublished: json['isPublished'] ?? false,
      publishedChannels: json['publishedChannels'] != null 
          ? Map<String, String>.from(json['publishedChannels']) 
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'instructions': instructions,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'knowledgeIds': knowledgeIds,
      'isPublished': isPublished,
      'publishedChannels': publishedChannels,
    };
  }
}

