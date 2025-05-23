class KnowledgeItem {
  final String id;
  final String title;
  final String content;
  final String fileUrl;
  final String fileType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;
  final int numUnits;
  final int totalSize;

  KnowledgeItem({
    required this.id,
    required this.title,
    required this.content,
    required this.fileUrl,
    required this.fileType,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.numUnits = 0,
    this.totalSize = 0,
  });

  KnowledgeItem copyWith({
    String? id,
    String? title,
    String? content,
    String? fileUrl,
    String? fileType,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    int? numUnits,
    int? totalSize,
  }) {
    return KnowledgeItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      numUnits: numUnits ?? this.numUnits,
      totalSize: totalSize ?? this.totalSize,
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
      'userId': userId,
      'numUnits': numUnits,
      'totalSize': totalSize,
    };
  }

  factory KnowledgeItem.fromJson(Map<String, dynamic> json) {
    return KnowledgeItem(
      id: json['id'] ??
          json['userId'] ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['knowledgeName'] ?? json['title'] ?? '',
      content: json['description'] ?? json['content'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'] ?? 'text',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      userId: json['userId'],
      numUnits: json['numUnits'] ?? 0,
      totalSize: json['totalSize'] ?? 0,
    );
  }
}
