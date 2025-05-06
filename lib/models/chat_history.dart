import 'conversation.dart';

class ChatHistory {
  final List<Conversation> conversations;
  final int totalMessages;
  final DateTime lastUpdated;

  ChatHistory({
    required this.conversations,
    required this.totalMessages,
    required this.lastUpdated,
  });

  factory ChatHistory.empty() {
    return ChatHistory(
      conversations: [],
      totalMessages: 0,
      lastUpdated: DateTime.now(),
    );
  }

  factory ChatHistory.fromConversations(List<Conversation> conversations) {
    int totalMessages = 0;
    DateTime lastUpdated = DateTime.now();

    if (conversations.isNotEmpty) {
      for (final conversation in conversations) {
        totalMessages += conversation.messages.length;
        if (conversation.updatedAt.isAfter(lastUpdated)) {
          lastUpdated = conversation.updatedAt;
        }
      }
    }

    return ChatHistory(
      conversations: conversations,
      totalMessages: totalMessages,
      lastUpdated: lastUpdated,
    );
  }

  ChatHistory copyWith({
    List<Conversation>? conversations,
    int? totalMessages,
    DateTime? lastUpdated,
  }) {
    return ChatHistory(
      conversations: conversations ?? this.conversations,
      totalMessages: totalMessages ?? this.totalMessages,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
