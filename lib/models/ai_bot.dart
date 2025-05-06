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
  final String? openAiAssistantId;
  final String? openAiThreadIdPlay;
  final String? createdBy;
  final String? updatedBy;

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
    this.openAiAssistantId,
    this.openAiThreadIdPlay,
    this.createdBy,
    this.updatedBy,
  });

  factory AIBot.empty() {
    return AIBot(
      id: '',
      name: '',
      description: '',
      instructions: '',
      avatarUrl: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      knowledgeIds: [],
      isPublished: false,
      publishedChannels: {},
    );
  }

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
    String? openAiAssistantId,
    String? openAiThreadIdPlay,
    String? createdBy,
    String? updatedBy,
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
      openAiAssistantId: openAiAssistantId ?? this.openAiAssistantId,
      openAiThreadIdPlay: openAiThreadIdPlay ?? this.openAiThreadIdPlay,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assistantName': name,
      'description': description,
      'instructions': instructions,
    };
  }

  factory AIBot.fromJson(Map<String, dynamic> json) {
    return AIBot(
      id: json['id'] ?? '',
      name: json['assistantName'] ?? '',
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
      openAiAssistantId: json['openAiAssistantId'],
      openAiThreadIdPlay: json['openAiThreadIdPlay'],
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
    );
  }
}
