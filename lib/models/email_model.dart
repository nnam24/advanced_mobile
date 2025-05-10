class EmailModel {
  final String id;
  final String subject;
  final String content;
  final String sender;
  final String receiver;
  final DateTime timestamp;
  final bool isRead;
  final List<String> labels;
  final bool isDraft; // Thêm trường này

  EmailModel({
    required this.id,
    required this.subject,
    required this.content,
    required this.sender,
    required this.receiver,
    required this.timestamp,
    this.isRead = false,
    this.labels = const [],
    this.isDraft = false, // Giá trị mặc định là false
  });

  factory EmailModel.fromJson(Map<String, dynamic> json) {
    return EmailModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      subject: json['subject'] ?? '',
      content: json['content'] ?? '',
      sender: json['sender'] ?? '',
      receiver: json['receiver'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      labels: json['labels'] != null
          ? List<String>.from(json['labels'])
          : [],
      isDraft: json['isDraft'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'content': content,
      'sender': sender,
      'receiver': receiver,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'labels': labels,
      'isDraft': isDraft,
    };
  }

  EmailModel copyWith({
    String? id,
    String? subject,
    String? content,
    String? sender,
    String? receiver,
    DateTime? timestamp,
    bool? isRead,
    List<String>? labels,
    bool? isDraft,
  }) {
    return EmailModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      labels: labels ?? this.labels,
      isDraft: isDraft ?? this.isDraft,
    );
  }
}
