import 'chat_message.dart';

/// Enhanced response with source transparency and confidence
class ChatbotResponse {
  final String text;
  final double confidence;
  final List<MessageSource> sources;
  final String
  responseType; // 'document_search', 'personal_data', 'greeting', etc.

  ChatbotResponse({
    required this.text,
    required this.confidence,
    required this.sources,
    required this.responseType,
  });

  /// Create response from document search
  factory ChatbotResponse.fromDocumentSearch({
    required String answer,
    required List<DocumentSourceInfo> documentSources,
  }) {
    final sources = documentSources
        .map(
          (doc) => MessageSource(
            type: 'document',
            name: doc.documentName,
            relevanceScore: doc.confidence,
            snippet: doc.snippet,
          ),
        )
        .toList();

    // Calculate overall confidence from multiple sources
    final avgConfidence = documentSources.isEmpty
        ? 0.0
        : documentSources.map((d) => d.confidence).reduce((a, b) => a + b) /
              documentSources.length;

    return ChatbotResponse(
      text: answer,
      confidence: avgConfidence,
      sources: sources,
      responseType: 'document_search',
    );
  }

  /// Create response from personal data
  factory ChatbotResponse.fromPersonalData({
    required String answer,
    required String fieldName,
  }) {
    return ChatbotResponse(
      text: answer,
      confidence: 1.0, // Personal data is always accurate
      sources: [
        MessageSource(
          type: 'personal_data',
          name: fieldName,
          relevanceScore: 1.0,
        ),
      ],
      responseType: 'personal_data',
    );
  }

  /// Create response from AI inference
  factory ChatbotResponse.fromAIInference({
    required String answer,
    required double confidence,
  }) {
    return ChatbotResponse(
      text: answer,
      confidence: confidence,
      sources: [
        MessageSource(
          type: 'ai_inference',
          name: 'Smart AI Service',
          relevanceScore: confidence,
        ),
      ],
      responseType: 'ai_inference',
    );
  }

  /// Format response with source transparency
  String formatWithSources({bool includeConfidence = true}) {
    final buffer = StringBuffer(text);

    // Add sources section if available
    if (sources.isNotEmpty && responseType != 'ai_inference') {
      buffer.writeln('\n');
      buffer.writeln('\n📚 Sources:');

      for (var i = 0; i < sources.length; i++) {
        final source = sources[i];
        if (source.type == 'document') {
          buffer.writeln(
            '  ${i + 1}. ${source.name} (${(source.relevanceScore * 100).toStringAsFixed(0)}% relevant)',
          );
        } else if (source.type == 'personal_data') {
          buffer.writeln('  ${i + 1}. Your ${source.name} (stored locally)');
        }
      }

      // Add confidence indicator if requested
      if (includeConfidence && confidence < 1.0) {
        buffer.writeln(
          '\n🎯 Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
        );
      }
    }

    return buffer.toString();
  }
}

/// Document source information
class DocumentSourceInfo {
  final String documentName;
  final double confidence;
  final String snippet;
  final int chunkIndex;

  DocumentSourceInfo({
    required this.documentName,
    required this.confidence,
    required this.snippet,
    this.chunkIndex = 0,
  });
}
