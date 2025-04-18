class KnowledgeUnit {
  final String id;
  final String name;
  final String type; // 'file', 'web', 'slack', etc.
  final int size;
  final bool status;
  final String userId;
  final String knowledgeId;
  final List<String> openAiFileIds;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  KnowledgeUnit({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.status,
    required this.userId,
    required this.knowledgeId,
    required this.openAiFileIds,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  KnowledgeUnit copyWith({
    String? id,
    String? name,
    String? type,
    int? size,
    bool? status,
    String? userId,
    String? knowledgeId,
    List<String>? openAiFileIds,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KnowledgeUnit(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      size: size ?? this.size,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      knowledgeId: knowledgeId ?? this.knowledgeId,
      openAiFileIds: openAiFileIds ?? this.openAiFileIds,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory KnowledgeUnit.fromJson(Map<String, dynamic> json) {
    return KnowledgeUnit(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'unknown',
      size: json['size'] ?? 0,
      status: json['status'] ?? true,
      userId: json['userId'] ?? '',
      knowledgeId: json['knowledgeId'] ?? '',
      openAiFileIds: json['openAiFileIds'] != null
          ? List<String>.from(json['openAiFileIds'])
          : [],
      metadata: json['metadata'] ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // Helper method to get source URL based on type
  String get sourceUrl {
    if (type == 'web' && metadata.containsKey('web_url')) {
      return metadata['web_url'] as String;
    } else if (type == 'slack' && metadata.containsKey('slack_workspace')) {
      return metadata['slack_workspace'] as String;
    } else if (type == 'file' && metadata.containsKey('file_name')) {
      return metadata['file_name'] as String;
    }
    return '';
  }
}
