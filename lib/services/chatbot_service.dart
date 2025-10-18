import '../models/personal_data.dart';
import 'local_data_service.dart';
import 'document_service.dart';
import 'smart_ai_service.dart';

/// Privacy-preserving chatbot service with source transparency
/// All processing happens locally - no external API calls
class ChatbotService {
  final LocalDataService _localDataService = LocalDataService();
  final DocumentService _documentService = DocumentService();
  final SmartAIService _aiService = SmartAIService();

  /// Initialize document service
  Future<void> initialize() async {
    await _documentService.loadDocuments();
  }

  /// Get document service instance
  DocumentService get documentService => _documentService;

  /// Process user query and generate response using local data only
  Future<String> processQuery(String query) async {
    final queryLower = query.toLowerCase().trim();

    // Use AI to classify intent
    final intent = _aiService.classifyIntent(query);
    final entities = _aiService.extractEntities(query);

    // PRIORITY 1: Handle greetings and farewells (but NOT help - let docs answer first!)
    if (intent.intent == 'greeting' || intent.intent == 'farewell') {
      // Only if it's JUST a greeting/farewell (no question words)
      if (!queryLower.contains('what') &&
          !queryLower.contains('how') &&
          !queryLower.contains('when') &&
          !queryLower.contains('where') &&
          !queryLower.contains('who') &&
          !queryLower.contains('why') &&
          !queryLower.contains('tell') &&
          !queryLower.contains('show') &&
          !queryLower.contains('find') &&
          !queryLower.contains('search')) {
        return _aiService.generateResponse(query: query, intent: intent);
      }
    }

    // PRIORITY 2: Check if query is asking about documents
    if (intent.intent == 'document_info') {
      return _getDocumentInfo();
    }

    // PRIORITY 3: Explicit search commands
    if (intent.intent == 'search_document' ||
        entities.containsKey('search_term')) {
      return await _searchDocuments(query);
    }

    // PRIORITY 4: Try answering from documents for ANY query (MOST IMPORTANT!)
    final docAnswer = await _tryAnswerFromDocuments(query);
    if (docAnswer != null && docAnswer.trim().isNotEmpty) {
      return docAnswer;
    }

    // PRIORITY 5: Only NOW check for help intent
    if (intent.intent == 'help') {
      return _aiService.generateResponse(query: query, intent: intent);
    }

    // FALLBACK: Check specific patterns for backward compatibility
    // Check if query is asking about documents
    if (_startsWithAny(queryLower, [
      'how many documents',
      'list documents',
      'show documents',
      'show my documents',
      'my documents',
      'loaded documents',
    ])) {
      return _getDocumentInfo();
    }

    // PRIORITY 2: Check if query is explicitly searching documents
    if (_startsWithAny(queryLower, [
      'search for ',
      'search documents for ',
      'find ',
      'look for ',
      'search ',
    ])) {
      return await _searchDocuments(query);
    }

    // PRIORITY 3: Get personal data from local storage
    final personalData = await _localDataService.getPersonalData();

    if (personalData == null) {
      return "I don't have any personal data stored yet. Please add your information first.";
    }

    // Pattern matching for various query types
    // All processing happens locally - no data sent to servers

    // Name queries
    if (_containsAny(queryLower, [
      'my name',
      'what is my name',
      'who am i',
      'what\'s my name',
    ])) {
      return "Your name is ${personalData.name}.";
    }

    // Email queries
    if (_containsAny(queryLower, [
      'my email',
      'email address',
      'what is my email',
    ])) {
      return "Your email address is ${personalData.email}.";
    }

    // Phone queries
    if (_containsAny(queryLower, [
      'my phone',
      'phone number',
      'contact number',
      'my number',
    ])) {
      return "Your phone number is ${personalData.phone}.";
    }

    // Address queries
    if (_containsAny(queryLower, [
      'my address',
      'where do i live',
      'my location',
      'where am i',
    ])) {
      return "Your address is ${personalData.address}.";
    }

    // Birthday queries
    if (_containsAny(queryLower, [
      'birthday',
      'birth date',
      'date of birth',
      'when was i born',
      'my dob',
    ])) {
      return "Your date of birth is ${personalData.dateOfBirth}.";
    }

    // Occupation queries
    if (_containsAny(queryLower, [
      'my job',
      'occupation',
      'what do i do',
      'my work',
      'profession',
    ])) {
      return "You work as a ${personalData.occupation}.";
    }

    // Interests queries
    if (_containsAny(queryLower, [
      'my interests',
      'hobbies',
      'what do i like',
      'my hobbies',
    ])) {
      return "Your interests include: ${personalData.interests.join(', ')}.";
    }

    // Preferences queries
    if (_containsAny(queryLower, ['favorite color', 'favourite color'])) {
      return "Your favorite color is ${personalData.preferences['favoriteColor'] ?? 'not set'}.";
    }

    if (_containsAny(queryLower, ['favorite food', 'favourite food'])) {
      return "Your favorite food is ${personalData.preferences['favoriteFood'] ?? 'not set'}.";
    }

    // Summary/profile queries
    if (_containsAny(queryLower, [
      'tell me about myself',
      'my profile',
      'my information',
      'my data',
      'who am i',
    ])) {
      return _generateProfileSummary(personalData);
    }

    // Help queries
    if (_containsAny(queryLower, [
      'help',
      'what can you do',
      'commands',
      'how to use',
    ])) {
      return _getHelpMessage();
    }

    // Default response
    return "I couldn't find that in your personal data. Try adding more details or load documents, then ask again.";
  }

  /// Check if query contains any of the patterns
  bool _containsAny(String query, List<String> patterns) {
    return patterns.any((pattern) => query.contains(pattern));
  }

  /// Check if query starts with any of the patterns
  bool _startsWithAny(String query, List<String> patterns) {
    return patterns.any((pattern) => query.startsWith(pattern));
  }

  /// Generate a summary of personal data
  String _generateProfileSummary(PersonalData data) {
    return """
Here's your profile summary:
• Name: ${data.name}
• Email: ${data.email}
• Phone: ${data.phone}
• Address: ${data.address}
• Date of Birth: ${data.dateOfBirth}
• Occupation: ${data.occupation}
• Interests: ${data.interests.join(', ')}
• Favorite Color: ${data.preferences['favoriteColor']}
• Favorite Food: ${data.preferences['favoriteFood']}

All this data is stored locally on your device and never sent to external servers.
    """
        .trim();
  }

  /// Get help message
  String _getHelpMessage() {
    return """
I'm a privacy-preserving chatbot. I can answer questions about your personal data stored locally on your device.

You can ask me about:
• Your name
• Email address
• Phone number
• Home address
• Date of birth
• Occupation
• Interests and hobbies
• Preferences (favorite color, food, etc.)
• Your complete profile

📄 Document Search:
• Load your documents using the + button
• Ask: "Search for [topic]" or "Find [keyword]"
• Your documents are indexed locally

Examples:
- "What is my name?"
- "Tell me my email"
- "What are my interests?"
- "Show me my profile"
- "Search for meeting notes"
- "Find information about budget"

🔒 Privacy: All your data stays on your device. Nothing is sent to external servers.
    """
        .trim();
  }

  /// Search documents using AI-powered ranking (LOCAL PROCESSING)
  Future<String> _searchDocuments(String query) async {
    final docs = _documentService.getDocuments();

    if (docs.isEmpty) {
      return "You haven't loaded any documents yet. Use the + button to add documents, then I can search through them for you.";
    }

    // Use AI to extract search terms
    final entities = _aiService.extractEntities(query);
    String searchQuery = entities['search_term'] as String? ?? query;

    // Fallback: Remove common search command patterns
    searchQuery = searchQuery.replaceAll(
      RegExp(
        r'^(search for|search documents for|find|look for|search)\s+',
        caseSensitive: false,
      ),
      '',
    );

    // Also remove trailing "in documents" etc
    searchQuery = searchQuery.replaceAll(
      RegExp(
        r'\s+(in documents|in my documents|documents)$',
        caseSensitive: false,
      ),
      '',
    );

    searchQuery = searchQuery.trim();

    if (searchQuery.isEmpty) {
      return "What would you like me to search for in your documents?";
    }

    // Step 1: use chunked search to get top contexts
    final topChunks = _documentService.searchTopChunks(
      searchQuery,
      maxChunks: 12,
    );
    if (topChunks.isEmpty) {
      return await _semanticFallback(searchQuery);
    }

    // Step 2: sentence-level QA across top chunks with improved accuracy
    final answers = <_CandidateAnswer>[];
    for (final c in topChunks.take(12)) {
      final qa = _aiService.extractRelevantSentences(
        searchQuery,
        c.chunkText,
        maxSentences: 3,
        minSentenceScore: 0.03, // Lowered from 0.05 for better recall
      );
      if (qa.sentences.isNotEmpty && qa.confidence >= 0.06) {
        // Lowered from 0.08
        answers.add(
          _CandidateAnswer(
            documentName: c.documentId,
            text: qa.sentences.join('. ').trim(),
            confidence: qa.confidence,
            chunkIndex: topChunks.indexOf(c),
            snippet: c.chunkText.length > 150
                ? '${c.chunkText.substring(0, 150)}...'
                : c.chunkText,
          ),
        );
      }
    }

    if (answers.isEmpty) {
      return await _semanticFallback(searchQuery);
    }

    // Sort by confidence
    answers.sort((a, b) => b.confidence.compareTo(a.confidence));

    // ENHANCED: Aggregate multiple high-confidence sources
    final topAnswers = answers
        .where((a) => a.confidence >= 0.12)
        .take(3)
        .toList();

    // If we have multiple good sources, combine them
    if (topAnswers.length > 1) {
      return _buildMultiSourceResponse(topAnswers, searchQuery);
    }

    // Single source response
    final best = answers.first;
    return _buildSingleSourceResponse(best);
  }

  /// Build response from multiple sources (improved accuracy with file names)
  String _buildMultiSourceResponse(
    List<_CandidateAnswer> sources,
    String query,
  ) {
    final buffer = StringBuffer();
    final primarySource = sources.first;

    // Enhanced: Show primary source file name at the top
    buffer.writeln('📄 From: ${primarySource.documentName}\n');

    // Main answer from best source
    final mainAnswer = primarySource.text.length > 350
        ? '${primarySource.text.substring(0, 350).trim()}…'
        : primarySource.text;

    buffer.writeln(mainAnswer);

    // Add supporting information from other sources if different
    var addedSupporting = false;
    for (var i = 1; i < sources.length; i++) {
      final supportingText = sources[i].text;
      // Only add if it contains new information (not too similar to main)
      if (!_isTooSimilar(mainAnswer, supportingText)) {
        if (!addedSupporting) {
          buffer.writeln('\n\n💡 Additional Information:');
          addedSupporting = true;
        }
        final snippet = supportingText.length > 200
            ? '${supportingText.substring(0, 200).trim()}…'
            : supportingText;
        buffer.writeln('\n📄 ${sources[i].documentName}:');
        buffer.writeln(snippet);
      }
    }

    // Enhanced source transparency section
    if (sources.length > 1) {
      buffer.writeln('\n\n━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('📚 All Relevant Sources (${sources.length}):');
      for (var i = 0; i < sources.length; i++) {
        final source = sources[i];
        final percentage = (source.confidence * 100).toStringAsFixed(0);
        final bars = '█' * ((source.confidence * 10).round());
        buffer.writeln(
          '  ${i + 1}. ${source.documentName}\n     $bars $percentage%',
        );
      }
    }

    // Overall confidence (average of top sources)
    final avgConfidence =
        sources.map((s) => s.confidence).reduce((a, b) => a + b) /
        sources.length;
    final confidencePercent = (avgConfidence * 100).toStringAsFixed(0);
    buffer.writeln('\n🎯 Confidence: $confidencePercent%');

    return buffer.toString().trim();
  }

  /// Build response from single source (with prominent file name)
  String _buildSingleSourceResponse(_CandidateAnswer answer) {
    final buffer = StringBuffer();

    // Enhanced: Show source file name at the top
    buffer.writeln('📄 From: ${answer.documentName}\n');

    // Show the answer
    final concise = answer.text.length > 400
        ? '${answer.text.substring(0, 400).trim()}…'
        : answer.text;

    buffer.writeln(concise);

    // Enhanced source transparency with visual confidence bar
    final confidencePercent = (answer.confidence * 100).toStringAsFixed(0);
    final bars = '█' * ((answer.confidence * 10).round()).clamp(0, 10);

    buffer.writeln('\n\n━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📚 Source: ${answer.documentName}');
    buffer.writeln('🎯 Confidence: $bars $confidencePercent%');

    return buffer.toString().trim();
  }

  /// Check if two texts are too similar (to avoid redundancy)
  bool _isTooSimilar(String text1, String text2) {
    final words1 = text1.toLowerCase().split(RegExp(r'\W+'));
    final words2 = text2.toLowerCase().split(RegExp(r'\W+'));

    final set1 = Set<String>.from(words1.where((w) => w.length > 3));
    final set2 = Set<String>.from(words2.where((w) => w.length > 3));

    if (set1.isEmpty || set2.isEmpty) return true;

    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;

    // If more than 70% similar, consider redundant
    return (intersection / union) > 0.7;
  }

  /// Try answering from documents for arbitrary queries (with source transparency)
  Future<String?> _tryAnswerFromDocuments(String query) async {
    final docs = _documentService.getDocuments();
    if (docs.isEmpty) return null;

    final topChunks = _documentService.searchTopChunks(query, maxChunks: 15);
    if (topChunks.isEmpty) return null;

    final answers = <_CandidateAnswer>[];
    for (final c in topChunks) {
      final qa = _aiService.extractRelevantSentences(
        query,
        c.chunkText,
        maxSentences: 3,
        minSentenceScore: 0.03, // Improved: lower threshold for better recall
      );
      if (qa.sentences.isNotEmpty && qa.confidence >= 0.06) {
        // Improved: lower threshold
        answers.add(
          _CandidateAnswer(
            documentName: c.documentId,
            text: qa.sentences.join('. ').trim(),
            confidence: qa.confidence,
            chunkIndex: topChunks.indexOf(c),
            snippet: c.chunkText.length > 150
                ? '${c.chunkText.substring(0, 150)}...'
                : c.chunkText,
          ),
        );
      }
    }

    if (answers.isEmpty) return null;

    answers.sort((a, b) => b.confidence.compareTo(a.confidence));

    // ENHANCED: Check for multiple good sources
    final topAnswers = answers
        .where((a) => a.confidence >= 0.1)
        .take(2)
        .toList();

    if (topAnswers.length > 1) {
      // Multi-source answer with transparency
      final buffer = StringBuffer();
      final best = topAnswers.first;

      final concise = best.text.length > 350
          ? '${best.text.substring(0, 350).trim()}…'
          : best.text;
      buffer.write(concise);

      // Add source info
      buffer.write('\n\n📚 From: ${best.documentName}');

      return buffer.toString();
    }

    // Single source answer
    final best = answers.first;
    final concise = best.text.length > 400
        ? '${best.text.substring(0, 400).trim()}…'
        : best.text;
    return concise;
  }

  Future<String> _semanticFallback(String query) async {
    final docs = _documentService.getDocuments();
    if (docs.isEmpty) {
      return "You haven't loaded any documents yet.";
    }
    final docDataList = docs
        .map((d) => DocumentData(id: d.id, name: d.name, content: d.content))
        .toList();
    final ranked = _aiService.rankDocuments(query, docDataList);
    if (ranked.isEmpty) {
      return "I couldn't find anything relevant in your documents.";
    }
    final top = ranked.first;
    final summary = _aiService.summarizeText(
      top.document.content,
      maxSentences: 2,
    );
    return summary.length > 300 ? '${summary.substring(0, 300)}…' : summary;
  }

  /// Get information about loaded documents
  String _getDocumentInfo() {
    final docs = _documentService.getDocuments();

    if (docs.isEmpty) {
      return "You haven't loaded any documents yet. Use the + button to add documents.";
    }

    final stats = _documentService.getStatistics();
    final buffer = StringBuffer();

    buffer.writeln("📄 Your Documents:\n");
    buffer.writeln("Total documents: ${stats['documentCount']}");
    buffer.writeln("Total words indexed: ${stats['totalWords']}");
    if (stats['chunkCount'] != null) {
      buffer.writeln("Chunks indexed: ${stats['chunkCount']}\n");
    } else {
      buffer.writeln("\n");
    }
    buffer.writeln("Loaded documents:");

    for (int i = 0; i < docs.length; i++) {
      final doc = docs[i];
      buffer.writeln("${i + 1}. ${doc.name}");
    }

    buffer.writeln(
      "\n💡 Try asking: 'Search for [topic]' to find information in your documents.",
    );
    buffer.writeln("🔒 All documents are stored and processed locally.");

    return buffer.toString().trim();
  }
}

class _CandidateAnswer {
  final String documentName;
  final String text;
  final double confidence;
  final int chunkIndex;
  final String snippet;

  _CandidateAnswer({
    required this.documentName,
    required this.text,
    required this.confidence,
    this.chunkIndex = 0,
    this.snippet = '',
  });
}
