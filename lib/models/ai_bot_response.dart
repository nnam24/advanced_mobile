import 'ai_bot.dart';

class AIBotResponse {
  final List<AIBot> data;
  final MetaData meta;

  AIBotResponse({
    required this.data,
    required this.meta,
  });

  factory AIBotResponse.fromJson(Map<String, dynamic> json) {
    List<AIBot> bots = [];

    if (json['data'] != null) {
      if (json['data'] is List) {
        bots = (json['data'] as List)
            .map((botJson) => AIBot.fromJson(botJson))
            .toList();
      }
    }

    return AIBotResponse(
      data: bots,
      meta: MetaData.fromJson(json['meta'] ?? {}),
    );
  }
}

class MetaData {
  final int limit;
  final int total;
  final int offset;
  final bool hasNext;

  MetaData({
    required this.limit,
    required this.total,
    required this.offset,
    required this.hasNext,
  });

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      limit: json['limit'] ?? 0,
      total: json['total'] ?? 0,
      offset: json['offset'] ?? 0,
      hasNext: json['hasNext'] ?? false,
    );
  }
}
