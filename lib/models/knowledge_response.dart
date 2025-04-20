class KnowledgeResponse {
  final List<dynamic> data;
  final KnowledgeMeta meta;

  KnowledgeResponse({
    required this.data,
    required this.meta,
  });

  factory KnowledgeResponse.fromJson(Map<String, dynamic> json) {
    return KnowledgeResponse(
      data: json['data'] ?? [],
      meta: KnowledgeMeta.fromJson(json['meta'] ?? {}),
    );
  }
}

class KnowledgeMeta {
  final int total;
  final int limit;
  final int offset;
  final bool hasNext;

  KnowledgeMeta({
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasNext,
  });

  factory KnowledgeMeta.fromJson(Map<String, dynamic> json) {
    return KnowledgeMeta(
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 10,
      offset: json['offset'] ?? 0,
      hasNext: json['hasNext'] ?? false,
    );
  }
}
