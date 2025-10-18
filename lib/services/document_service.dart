import 'dart:io';
import 'dart:convert';
import 'dart:math';
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
  Future<void> deleteDocumentAndFile(String id) async {
    try {
      final doc = _documents.firstWhere((d) => d.id == id);
      final path = doc.filePath;
      if (path != null && path.isNotEmpty) {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      }
    } catch (_) {
      // If not found or delete fails, continue to remove from index
    }
    await removeDocument(id);
  }

  /// Clear all documents
  Future<void> clearAllDocuments() async {
    _documents.clear();
    _tfidfIndex.clear();
    _chunks.clear();
    _chunkIndex.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_documentsKey);
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
  List<SearchResult> search(String query, {int maxResults = 5}) {
    if (_documents.isEmpty || query.trim().isEmpty) {
      return [];
    }

    final queryWords = _tokenize(query);
    final scores = <String, double>{};

    // First, score chunks using BM25-like index for better recall
    final chunkScores = <String, double>{};
    for (final entry in _chunkIndex.entries) {
      double score = 0.0;
      for (final word in queryWords) {
        score += entry.value[word] ?? 0.0;
      }
      if (score > 0) chunkScores[entry.key] = score;
    }

    // Aggregate chunk scores per document and keep best chunk for snippet
    final docBestChunk = <String, String>{}; // docId -> chunkId
    for (final cs in chunkScores.entries) {
      final chunk = _chunks[cs.key]!;
      final docId = chunk.documentId;
      scores[docId] = (scores[docId] ?? 0.0) + cs.value;
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
        snippet = _extractRelevantSnippet(
          _chunks[bestChunkId]!.text,
          queryWords,
        );
      } else {
        snippet = _extractRelevantSnippet(doc.content, queryWords);
      }
      results.add(
        SearchResult(document: doc, score: scores[id]!, snippet: snippet),
      );
    }

    return results;
  }

  /// Return top-N chunk texts across all documents for a query, with scores
  List<ChunkSearchResult> searchTopChunks(String query, {int maxChunks = 12}) {
    if (_documents.isEmpty || query.trim().isEmpty) return [];
    final queryWords = _tokenize(query);
    final chunkScores = <String, double>{};

    // Score each chunk
    for (final entry in _chunkIndex.entries) {
      double score = 0.0;
      for (final w in queryWords) {
        score += entry.value[w] ?? 0.0;
      }
      if (score > 0) {
        chunkScores[entry.key] = score;
      }
    }

    // If no TF-IDF matches, do a simpler word matching with fuzzy support
    if (chunkScores.isEmpty) {
      final simpleQueryWords = query
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 2)
          .toList();

      for (final entry in _chunks.entries) {
        final chunkText = entry.value.text.toLowerCase();
        final chunkWords = chunkText.split(RegExp(r'\s+'));
        double matches = 0;

        for (final queryWord in simpleQueryWords) {
          // Exact match
          if (chunkText.contains(queryWord)) {
            matches += 1.0;
          } else {
            // Fuzzy match for spelling mistakes
            for (final chunkWord in chunkWords) {
              if (chunkWord.length > 2) {
                final similarity = _calculateSimilarity(queryWord, chunkWord);
                if (similarity > 0.75) {
                  // 75% similarity for fuzzy match
                  matches += 0.7 * similarity; // Lower score for fuzzy
                  break;
                }
              }
            }
          }
        }

        if (matches > 0) {
          chunkScores[entry.key] =
              matches * 0.5; // Lower score for simple match
        }
      }
    }

    final sorted = chunkScores.keys.toList()
      ..sort((a, b) => chunkScores[b]!.compareTo(chunkScores[a]!));
    final results = <ChunkSearchResult>[];
    for (final id in sorted.take(maxChunks)) {
      final c = _chunks[id]!;
      results.add(
        ChunkSearchResult(
          documentId: c.documentId,
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

  /// Extract relevant snippet from document
  String _extractRelevantSnippet(String content, List<String> queryWords) {
    const maxLength = 200;
    final sentences = content.split(RegExp(r'[.!?]\s+'));

    // Find sentence with most query words
    int bestScore = 0;
    String bestSentence = '';

    for (var sentence in sentences) {
      final sentenceLower = sentence.toLowerCase();
      int score = 0;

      for (var word in queryWords) {
        if (sentenceLower.contains(word)) {
          score++;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestSentence = sentence.trim();
      }
    }

    if (bestSentence.isEmpty && sentences.isNotEmpty) {
      bestSentence = sentences.first.trim();
    }

    // Truncate if too long
    if (bestSentence.length > maxLength) {
      return '${bestSentence.substring(0, maxLength)}...';
    }

    return bestSentence;
  }

  /// Get statistics about loaded documents
  Map<String, dynamic> getStatistics() {
    final totalWords = _documents.fold<int>(
      0,
      (sum, doc) => sum + _tokenize(doc.content).length,
    );

    return {
      'documentCount': _documents.length,
      'totalWords': totalWords,
      'chunkCount': _chunks.length,
    };
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

  SearchResult({
    required this.document,
    required this.score,
    required this.snippet,
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
