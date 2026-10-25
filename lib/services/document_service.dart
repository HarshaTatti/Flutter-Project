import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document.dart';

/// Service to manage document loading and intelligent indexing
/// All processing happens locally - no external servers
class DocumentService {
  static const String _documentsKey = 'loaded_documents';
  final List<Document> _documents = [];
  final Map<String, Map<String, double>> _tfidfIndex = {};
  // Chunk-level indexing for better recall and snippets
  final Map<String, _Chunk> _chunks = {}; // chunkId -> chunk
  final Map<String, Map<String, double>> _chunkIndex =
      {}; // chunkId -> {term: weight}

  /// Load documents from local storage
  Future<void> loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final docsString = prefs.getString(_documentsKey);

    if (docsString != null) {
      final List<dynamic> docsList = jsonDecode(docsString);
      _documents.clear();
      _documents.addAll(docsList.map((json) => Document.fromJson(json)));
      _buildIndex();
    }
  }

  /// Save documents to local storage
  Future<void> _saveDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final docsJson = jsonEncode(_documents.map((d) => d.toJson()).toList());
    await prefs.setString(_documentsKey, docsJson);
  }

  /// Add a new document and update index
  Future<void> addDocument(
    String name,
    String content, {
    String? filePath,
    int? sizeBytes,
  }) async {
    final doc = Document(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      content: content,
      filePath: filePath,
      sizeBytes: sizeBytes,
    );

    _documents.add(doc);
    await _saveDocuments();
    _buildIndex();
  }

  /// Get all loaded documents
  List<Document> getDocuments() => List.unmodifiable(_documents);

  /// Remove a document
  Future<void> removeDocument(String id) async {
    _documents.removeWhere((doc) => doc.id == id);
    await _saveDocuments();
    _buildIndex();
  }

  /// Delete a document and its local file (if any), then reindex
  /// This completely removes the document from storage and reduces app data
  Future<void> deleteDocumentAndFile(String id) async {
    try {
      final doc = _documents.firstWhere((d) => d.id == id);

      // Delete the physical file if it exists (non-web)
      final path = doc.filePath;
      if (!kIsWeb && path != null && path.isNotEmpty) {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
          debugPrint('Deleted file: $path');
        }
      }

      // Remove all chunks associated with this document
      final chunkIds = _chunks.keys
          .where((key) => key.startsWith('${doc.id}_'))
          .toList();
      for (final chunkId in chunkIds) {
        _chunks.remove(chunkId);
        _chunkIndex.remove(chunkId);
      }

      // Remove document index
      _tfidfIndex.remove(doc.id);

      // Remove from document list
      _documents.removeWhere((d) => d.id == id);

      // Save updated document list (this reduces SharedPreferences storage)
      await _saveDocuments();

      // Rebuild index to ensure consistency
      _buildIndex();

      debugPrint('Document $id deleted. Storage reduced.');
    } catch (e) {
      debugPrint('Error deleting document $id: $e');
      // If not found or delete fails, still try to remove from index
      await removeDocument(id);
    }
  }

  /// Clear all documents and their physical files
  /// This completely removes all document data and frees up storage
  Future<void> clearAllDocuments() async {
    // Delete all physical files (non-web)
    if (!kIsWeb) {
      for (final doc in _documents) {
        final path = doc.filePath;
        if (path != null && path.isNotEmpty) {
          try {
            final f = File(path);
            if (await f.exists()) {
              await f.delete();
              debugPrint('Deleted file: $path');
            }
          } catch (e) {
            debugPrint('Error deleting file $path: $e');
          }
        }
      }
    }

    // Clear all in-memory data structures
    _documents.clear();
    _tfidfIndex.clear();
    _chunks.clear();
    _chunkIndex.clear();

    // Remove from persistent storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_documentsKey);

    debugPrint('All documents cleared. Storage freed.');
  }

  /// Build TF-IDF index for all documents (LOCAL PROCESSING)
  void _buildIndex() {
    _tfidfIndex.clear();
    _chunks.clear();
    _chunkIndex.clear();

    if (_documents.isEmpty) return;

    // Calculate term frequency for each document
    final Map<String, Map<String, int>> termFrequency = {};
    final Map<String, int> documentFrequency = {};
    // Also build chunk structures
    final Map<String, Map<String, int>> chunkTF =
        {}; // chunkId -> term -> count
    final Map<String, int> chunkDF = {}; // term -> in how many chunks

    for (var doc in _documents) {
      final words = _tokenize(doc.content);
      final uniqueWords = words.toSet();

      termFrequency[doc.id] = {};
      for (var word in words) {
        termFrequency[doc.id]![word] = (termFrequency[doc.id]![word] ?? 0) + 1;
      }

      // Count document frequency
      for (var word in uniqueWords) {
        documentFrequency[word] = (documentFrequency[word] ?? 0) + 1;
      }

      // Create chunks (characters-based with overlap)
      final chunks = _createChunks(doc);
      for (final chunk in chunks) {
        _chunks[chunk.id] = chunk;
        final wordsChunk = _tokenize(chunk.text);
        chunkTF[chunk.id] = {};
        final chunkUnique = <String>{};
        for (final w in wordsChunk) {
          chunkTF[chunk.id]![w] = (chunkTF[chunk.id]![w] ?? 0) + 1;
          chunkUnique.add(w);
        }
        for (final w in chunkUnique) {
          chunkDF[w] = (chunkDF[w] ?? 0) + 1;
        }
      }
    }

    // Calculate TF-IDF (document level)
    final numDocs = _documents.length;
    for (var doc in _documents) {
      _tfidfIndex[doc.id] = {};
      final tf = termFrequency[doc.id]!;
      final maxFreq = tf.values.isEmpty ? 1 : tf.values.reduce(max);

      for (var entry in tf.entries) {
        final word = entry.key;
        final freq = entry.value;

        // TF: normalized frequency
        final tfScore = freq / maxFreq;

        // IDF: log(N / df)
        final df = documentFrequency[word]!;
        final idfScore = log(numDocs / df);

        // TF-IDF
        _tfidfIndex[doc.id]![word] = tfScore * idfScore;
      }
    }

    // Calculate TF-IDF (chunk level) using BM25-like weighting
    final numChunks = _chunks.length;
    final avgChunkLen =
        _chunks.values
            .map((c) => _tokenize(c.text).length)
            .fold<int>(0, (a, b) => a + b) /
        (numChunks == 0 ? 1 : numChunks);
    const k1 = 1.5;
    const b = 0.75;

    for (final entry in _chunks.entries) {
      final chunkId = entry.key;
      final tf = chunkTF[chunkId] ?? {};
      final chunkLen = tf.values.fold<int>(0, (a, b) => a + b);
      _chunkIndex[chunkId] = {};
      for (final e in tf.entries) {
        final term = e.key;
        final freq = e.value;
        final df = chunkDF[term] ?? 1;
        final idf = log(((numChunks - df + 0.5) / (df + 0.5)).clamp(0.01, 1e9));
        final denom =
            freq +
            k1 *
                (1 - b + b * (chunkLen / (avgChunkLen == 0 ? 1 : avgChunkLen)));
        final score = idf * (freq * (k1 + 1)) / (denom == 0 ? 1 : denom);
        _chunkIndex[chunkId]![term] = score;
      }
    }
  }

  /// Search documents using TF-IDF (LOCAL QUERY PROCESSING)
  /// Enhanced with better accuracy and context-aware ranking
  List<SearchResult> search(String query, {int maxResults = 5}) {
    if (_documents.isEmpty || query.trim().isEmpty) {
      return [];
    }

    final queryWords = _tokenize(query);
    final scores = <String, double>{};

    // Enhanced scoring: score chunks using BM25-like index
    final chunkScores = <String, double>{};
    for (final entry in _chunkIndex.entries) {
      double score = 0.0;
      int matchedTerms = 0;

      for (final word in queryWords) {
        final termScore = entry.value[word] ?? 0.0;
        if (termScore > 0) {
          score += termScore;
          matchedTerms++;
        }
      }

      // Boost score if multiple query terms match (phrase proximity bonus)
      if (matchedTerms > 1) {
        score *= (1.0 + (matchedTerms * 0.2)); // 20% bonus per matched term
      }

      // Check for exact phrase matches (highest priority)
      final chunkText = _chunks[entry.key]!.text.toLowerCase();
      if (chunkText.contains(query.toLowerCase())) {
        score *= 2.5; // 150% bonus for exact phrase match
      }

      if (score > 0) chunkScores[entry.key] = score;
    }

    // Aggregate chunk scores per document and keep best chunks
    final docBestChunk = <String, String>{}; // docId -> chunkId
    final docAllChunks = <String, List<String>>{}; // docId -> [chunkIds]

    for (final cs in chunkScores.entries) {
      final chunk = _chunks[cs.key]!;
      final docId = chunk.documentId;
      scores[docId] = (scores[docId] ?? 0.0) + cs.value;

      // Track all relevant chunks
      docAllChunks.putIfAbsent(docId, () => []).add(cs.key);

      final currentBest = docBestChunk[docId];
      if (currentBest == null ||
          (chunkScores[cs.key]! > (chunkScores[currentBest] ?? 0.0))) {
        docBestChunk[docId] = cs.key;
      }
    }

    // Sort by score and return top results
    final sortedIds = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    final results = <SearchResult>[];
    for (var id in sortedIds.take(maxResults)) {
      final doc = _documents.firstWhere((d) => d.id == id);
      String snippet;
      final bestChunkId = docBestChunk[id];

      if (bestChunkId != null) {
        // Extract snippet from best matching chunk
        snippet = _extractRelevantSnippet(
          _chunks[bestChunkId]!.text,
          queryWords,
          query: query,
        );
      } else {
        snippet = _extractRelevantSnippet(
          doc.content,
          queryWords,
          query: query,
        );
      }

      // Add context from multiple relevant chunks if available
      final allChunkIds = docAllChunks[id] ?? [];
      if (allChunkIds.length > 1) {
        // Sort chunks by score
        allChunkIds.sort(
          (a, b) => (chunkScores[b] ?? 0.0).compareTo(chunkScores[a] ?? 0.0),
        );

        // Include additional context from top chunks
        final additionalContext = <String>[];
        for (int i = 1; i < min(3, allChunkIds.length); i++) {
          final contextSnippet = _extractRelevantSnippet(
            _chunks[allChunkIds[i]]!.text,
            queryWords,
            maxLength: 100,
          );
          if (contextSnippet.isNotEmpty && !snippet.contains(contextSnippet)) {
            additionalContext.add(contextSnippet);
          }
        }

        if (additionalContext.isNotEmpty) {
          snippet = '$snippet ... ${additionalContext.join(" ... ")}';
        }
      }

      results.add(
        SearchResult(
          document: doc,
          score: scores[id]!,
          snippet: snippet,
          relevantChunks: allChunkIds.length,
        ),
      );
    }

    return results;
  }

  /// Return top-N chunk texts across all documents for a query, with scores
  /// ENHANCED: Multi-strategy ranking for maximum accuracy
  List<ChunkSearchResult> searchTopChunks(String query, {int maxChunks = 12}) {
    if (_documents.isEmpty || query.trim().isEmpty) return [];

    final queryWords = _tokenize(query);
    final queryLower = query.toLowerCase();
    final chunkScores = <String, double>{};

    // STRATEGY 1: TF-IDF scoring with enhanced weighting
    for (final entry in _chunkIndex.entries) {
      double score = 0.0;
      int matchedTerms = 0;

      for (final w in queryWords) {
        final termScore = entry.value[w] ?? 0.0;
        if (termScore > 0) {
          score += termScore;
          matchedTerms++;
        }
      }

      if (score > 0) {
        // Bonus for matching multiple terms
        if (matchedTerms > 1) {
          score *= (1.0 + (matchedTerms * 0.25));
        }
        chunkScores[entry.key] = score;
      }
    }

    // STRATEGY 2: Exact phrase matching (HIGHEST PRIORITY)
    for (final entry in _chunks.entries) {
      final chunkText = entry.value.text.toLowerCase();

      // Exact phrase match - massive boost
      if (chunkText.contains(queryLower)) {
        final currentScore = chunkScores[entry.key] ?? 0.0;
        chunkScores[entry.key] = currentScore + 10.0; // Big bonus

        // Extra boost if phrase is near the beginning (often more relevant)
        final position = chunkText.indexOf(queryLower);
        if (position < 100) {
          chunkScores[entry.key] = chunkScores[entry.key]! + 2.0;
        }
      }

      // STRATEGY 3: Whole word boundary matching
      for (final queryWord in queryWords) {
        if (queryWord.length > 3) {
          final wordBoundary = RegExp(r'\b' + RegExp.escape(queryWord) + r'\b');
          final matches = wordBoundary.allMatches(chunkText).length;
          if (matches > 0) {
            final currentScore = chunkScores[entry.key] ?? 0.0;
            // Boost for each whole word match
            chunkScores[entry.key] = currentScore + (matches * 0.8);
          }
        }
      }
    }

    // STRATEGY 4: Semantic proximity (terms appearing close together)
    for (final entry in _chunks.entries) {
      final chunkText = entry.value.text.toLowerCase();
      if (queryWords.length > 1) {
        // Find positions of all query words
        final positions = <int>[];
        for (final word in queryWords) {
          int pos = chunkText.indexOf(word);
          if (pos != -1) {
            positions.add(pos);
          }
        }

        // If multiple terms found, check proximity
        if (positions.length > 1) {
          positions.sort();
          // Calculate average distance between terms
          int totalDistance = 0;
          for (int i = 1; i < positions.length; i++) {
            totalDistance += (positions[i] - positions[i - 1]);
          }
          final avgDistance = totalDistance / (positions.length - 1);

          // Closer terms = higher relevance
          if (avgDistance < 100) {
            final proximityBonus = (100 - avgDistance) / 50;
            final currentScore = chunkScores[entry.key] ?? 0.0;
            chunkScores[entry.key] = currentScore + proximityBonus;
          }
        }
      }
    }

    // STRATEGY 5: Fuzzy matching for typos (fallback only)
    if (chunkScores.isEmpty || chunkScores.values.every((s) => s < 0.5)) {
      final simpleQueryWords = query
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 3)
          .toList();

      for (final entry in _chunks.entries) {
        final chunkText = entry.value.text.toLowerCase();
        final chunkWords = chunkText
            .split(RegExp(r'\W+'))
            .where((w) => w.length > 3)
            .toList();
        double fuzzyScore = 0;

        for (final queryWord in simpleQueryWords) {
          // First try substring match
          if (chunkText.contains(queryWord)) {
            fuzzyScore += 1.0;
            continue;
          }

          // Then try fuzzy matching
          for (final chunkWord in chunkWords) {
            final similarity = _calculateSimilarity(queryWord, chunkWord);
            if (similarity > 0.8) {
              fuzzyScore += similarity * 0.6;
              break;
            }
          }
        }

        if (fuzzyScore > 0) {
          final currentScore = chunkScores[entry.key] ?? 0.0;
          chunkScores[entry.key] = currentScore + (fuzzyScore * 0.4);
        }
      }
    }

    // Sort by score and return top results
    final sorted = chunkScores.keys.toList()
      ..sort((a, b) => chunkScores[b]!.compareTo(chunkScores[a]!));

    final results = <ChunkSearchResult>[];
    for (final id in sorted.take(maxChunks)) {
      final c = _chunks[id]!;
      final doc = _documents.firstWhere((d) => d.id == c.documentId);
      results.add(
        ChunkSearchResult(
          documentId: doc.name, // Use document name instead of ID
          chunkText: c.text,
          score: chunkScores[id]!,
        ),
      );
    }
    return results;
  }

  /// Tokenize text into words (simple implementation)
  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2) // Filter short words
        .where((word) => !_isStopWord(word)) // Filter common words
        .toList();
  }

  /// Check if word is a common stop word
  bool _isStopWord(String word) {
    const stopWords = {
      'the',
      'is',
      'at',
      'on',
      'and',
      'a',
      'an',
      'as',
      'are',
      'was',
      'were',
      'been',
      'be',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'should',
      'could',
      'may',
      'might',
      'must',
      'can',
      'this',
      'that',
      'these',
      'those',
      'you',
      'he',
      'she',
      'we',
      'they',
      'them',
      'their',
      'what',
      'who',
      'when',
      'where',
      'why',
      'how',
      'all',
      'each',
      'every',
      'both',
      'few',
      'more',
      'most',
      'other',
      'some',
      'such',
      'no',
      'nor',
      'not',
      'only',
      'own',
      'same',
      'so',
      'than',
      'too',
      'very',
      'for',
      'in',
      'to',
      'of',
      'from',
      'with',
      'by',
      'about',
      'into',
      'through',
      'during',
      'before',
      'after',
    };
    return stopWords.contains(word);
  }

  /// Extract relevant snippet from document with enhanced accuracy
  String _extractRelevantSnippet(
    String content,
    List<String> queryWords, {
    String? query,
    int maxLength = 250,
  }) {
    // First, try to find exact phrase match
    if (query != null && query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      final contentLower = content.toLowerCase();
      final index = contentLower.indexOf(queryLower);

      if (index != -1) {
        // Found exact phrase, extract context around it
        final start = max(0, index - 50);
        final end = min(content.length, index + query.length + 150);
        String snippet = content.substring(start, end).trim();

        if (start > 0) snippet = '...$snippet';
        if (end < content.length) snippet = '$snippet...';

        return snippet;
      }
    }

    // Split into sentences with better handling of various punctuation
    final sentences = content.split(RegExp(r'[.!?]\s+|[\n]{2,}'));

    // Find sentences with most query words
    final scoredSentences = <({int score, String sentence, int position})>[];

    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i].trim();
      if (sentence.isEmpty) continue;

      final sentenceLower = sentence.toLowerCase();
      int score = 0;
      int exactMatches = 0;

      // Count query word matches
      for (var word in queryWords) {
        if (sentenceLower.contains(word)) {
          score++;
          // Check if it's a whole word match (more accurate)
          if (RegExp(
            r'\b' + RegExp.escape(word) + r'\b',
          ).hasMatch(sentenceLower)) {
            exactMatches++;
          }
        }
      }

      // Boost score for exact word matches
      score += exactMatches;

      // Slight boost for sentences near the beginning (often more important)
      if (i < 3) score += 1;

      if (score > 0) {
        scoredSentences.add((score: score, sentence: sentence, position: i));
      }
    }

    if (scoredSentences.isEmpty && sentences.isNotEmpty) {
      // No matches found, return first meaningful sentence
      for (final sentence in sentences) {
        final trimmed = sentence.trim();
        if (trimmed.length > 20) {
          return trimmed.length > maxLength
              ? '${trimmed.substring(0, maxLength)}...'
              : trimmed;
        }
      }
      return sentences.first.trim();
    }

    // Sort by score (descending), then by position (ascending for earlier sentences)
    scoredSentences.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.position.compareTo(b.position);
    });

    // Get best sentences and combine if they're adjacent
    final bestSentences = scoredSentences.take(2).toList();
    String snippet;

    if (bestSentences.length > 1 &&
        (bestSentences[0].position - bestSentences[1].position).abs() == 1) {
      // Adjacent sentences, combine them
      final sortedByPosition = bestSentences
        ..sort((a, b) => a.position.compareTo(b.position));
      snippet = sortedByPosition.map((s) => s.sentence).join(' ');
    } else {
      snippet = bestSentences.first.sentence;
    }

    // Truncate if too long
    if (snippet.length > maxLength) {
      // Try to truncate at a word boundary
      int truncateAt = maxLength;
      final lastSpace = snippet.lastIndexOf(' ', maxLength);
      if (lastSpace > maxLength - 50) {
        truncateAt = lastSpace;
      }
      return '${snippet.substring(0, truncateAt)}...';
    }

    return snippet;
  }

  /// Get statistics about loaded documents
  Map<String, dynamic> getStatistics() {
    final totalWords = _documents.fold<int>(
      0,
      (sum, doc) => sum + _tokenize(doc.content).length,
    );

    final totalSize = _documents.fold<int>(
      0,
      (sum, doc) => sum + (doc.sizeBytes ?? doc.content.length),
    );

    final totalChars = _documents.fold<int>(
      0,
      (sum, doc) => sum + doc.content.length,
    );

    return {
      'documentCount': _documents.length,
      'totalWords': totalWords,
      'chunkCount': _chunks.length,
      'totalSizeBytes': totalSize,
      'totalCharacters': totalChars,
      'storageMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  /// Get storage size for a specific document
  int getDocumentSize(String id) {
    try {
      final doc = _documents.firstWhere((d) => d.id == id);
      return doc.sizeBytes ?? doc.content.length;
    } catch (_) {
      return 0;
    }
  }

  /// Calculate similarity between two strings (for fuzzy matching)
  /// Returns 0.0 to 1.0 (1.0 = exact match, 0.0 = completely different)
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    // Skip if length difference is too large
    if ((s1.length - s2.length).abs() > 3) return 0.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLen = max(s1.length, s2.length);

    // Convert distance to similarity score (0-1)
    final similarity = 1.0 - (distance / maxLen);
    return similarity;
  }

  /// Calculate Levenshtein distance (edit distance) between two strings
  int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    // Create a matrix
    final matrix = List.generate(len1 + 1, (i) => List.filled(len2 + 1, 0));

    // Initialize first row and column
    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // Calculate distances
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = min(
          min(
            matrix[i - 1][j] + 1, // deletion
            matrix[i][j - 1] + 1, // insertion
          ),
          matrix[i - 1][j - 1] + cost, // substitution
        );
      }
    }

    return matrix[len1][len2];
  }
}

/// Search result with document and relevance score
class SearchResult {
  final Document document;
  final double score;
  final String snippet;
  final int relevantChunks; // Number of chunks that matched the query

  SearchResult({
    required this.document,
    required this.score,
    required this.snippet,
    this.relevantChunks = 1,
  });
}

class _Chunk {
  final String id;
  final String documentId;
  final int index;
  final String text;

  _Chunk({
    required this.id,
    required this.documentId,
    required this.index,
    required this.text,
  });
}

List<_Chunk> _createChunks(
  Document doc, {
  int chunkSize = 800,
  int overlap = 120,
}) {
  final text = doc.content;
  final chunks = <_Chunk>[];
  if (text.isEmpty) return chunks;
  int start = 0;
  int i = 0;
  while (start < text.length) {
    final end = (start + chunkSize) > text.length
        ? text.length
        : (start + chunkSize);
    final chunkText = text.substring(start, end);
    chunks.add(
      _Chunk(id: '${doc.id}_$i', documentId: doc.id, index: i, text: chunkText),
    );
    if (end == text.length) break;
    start = end - overlap;
    if (start < 0) start = 0;
    i++;
  }
  return chunks;
}

/// Chunk search result
class ChunkSearchResult {
  final String documentId;
  final String chunkText;
  final double score;

  ChunkSearchResult({
    required this.documentId,
    required this.chunkText,
    required this.score,
  });
}
