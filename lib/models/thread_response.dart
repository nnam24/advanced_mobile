class ThreadResponse {
  final String id;
  final String assistantId;
  final String openAiThreadId;
  final String threadName;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ThreadResponse({
    required this.id,
    required this.assistantId,
    required this.openAiThreadId,
    required this.threadName,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ThreadResponse.fromJson(Map<String, dynamic> json) {
    // Print the raw JSON to debug
    print('Parsing ThreadResponse from JSON: $json');

    // Try to extract the thread ID with different possible capitalizations
    String threadId = '';
    if (json.containsKey('openAiThreadId')) {
      threadId = json['openAiThreadId'] ?? '';
    } else if (json.containsKey('openAIThreadId')) {
      threadId = json['openAIThreadId'] ?? '';
    }

    print('Extracted thread ID: $threadId');

    return ThreadResponse(
      id: json['id'] ?? '',
      assistantId: json['assistantId'] ?? '',
      openAiThreadId: threadId,
      threadName: json['threadName'] ?? '',
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
