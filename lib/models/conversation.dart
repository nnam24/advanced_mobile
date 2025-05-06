import 'message.dart';

class Conversation {
  final String id;
  final String title;
  final String agentName;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.title,
    required this.agentName,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Conversation copyWith({
    String? id,
    String? title,
    String? agentName,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      agentName: agentName ?? this.agentName,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Conversation.empty() {
    final now = DateTime.now();
    return Conversation(
      id: 'temp_${now.millisecondsSinceEpoch}', // Temporary ID that will be replaced with the real conversation ID from the API
      title: 'New Conversation',
      agentName: 'Claude 3.5 Sonnet',
      messages: [],
      createdAt: now,
      updatedAt: now,
    );
  }
}
