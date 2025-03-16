class KnowledgeItem {
  final String id;
  final String title;
  final String content;
  final String fileUrl;
  final String fileType;
  final DateTime createdAt;
  final DateTime updatedAt;

  KnowledgeItem({
    required this.id,
    required this.title,
    required this.content,
    required this.fileUrl,
    required this.fileType,
    required this.createdAt,
    required this.updatedAt,
  });

  KnowledgeItem copyWith({
    String? id,
    String? title,
    String? content,
    String? fileUrl,
    String? fileType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KnowledgeItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory KnowledgeItem.empty() {
    return KnowledgeItem(
      id: '',
      title: '',
      content: '',
      fileUrl: '',
      fileType: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory KnowledgeItem.fromJson(Map<String, dynamic> json) {
    return KnowledgeItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

