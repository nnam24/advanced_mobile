enum MessageType { user, assistant, image }

class Message {
  final String id;
  final String content;
  final MessageType type;
  final DateTime? timestamp;
  final int tokenCount;
  final String? imageUrl; // Added for image messages
  final String? imageCaption; // Optional caption for images

  Message({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.tokenCount = 0,
    this.imageUrl,
    this.imageCaption,
  });

  Message copyWith({
    String? id,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    int? tokenCount,
    String? imageUrl,
    String? imageCaption,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      tokenCount: tokenCount ?? this.tokenCount,
      imageUrl: imageUrl ?? this.imageUrl,
      imageCaption: imageCaption ?? this.imageCaption,
    );
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}
