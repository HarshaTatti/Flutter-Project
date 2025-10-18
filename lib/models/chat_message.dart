/// Model class to represent a chat message with source transparency
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<MessageSource>? sources; // Source transparency
  final double? confidence; // Response confidence score

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.sources,
    this.confidence,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'sources': sources?.map((s) => s.toJson()).toList(),
      'confidence': confidence,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      sources: json['sources'] != null
          ? (json['sources'] as List)
                .map((s) => MessageSource.fromJson(s))
                .toList()
          : null,
      confidence: json['confidence'],
    );
  }
}

/// Source information for transparency
class MessageSource {
  final String type; // 'document', 'personal_data', 'ai_inference'
  final String name; // Document name or data field
  final double relevanceScore; // How relevant this source was
  final String? snippet; // Optional text snippet from source

  MessageSource({
    required this.type,
    required this.name,
    required this.relevanceScore,
    this.snippet,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'relevanceScore': relevanceScore,
      'snippet': snippet,
    };
  }

  factory MessageSource.fromJson(Map<String, dynamic> json) {
    return MessageSource(
      type: json['type'],
      name: json['name'],
      relevanceScore: json['relevanceScore'],
      snippet: json['snippet'],
    );
  }
}
