import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Lightweight offline extractor to convert common office files to plain text
class FileTextExtractor {
  /// Detect file type from name and delegate extraction
  /// Supports: PDF, DOCX, PPTX, TXT, MD, CSV, JSON, XML, HTML, RTF, and more
  static Future<String> extractText({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final lower = fileName.toLowerCase();

    // Plain text formats
    if (lower.endsWith('.txt') ||
        lower.endsWith('.md') ||
        lower.endsWith('.markdown') ||
        lower.endsWith('.log') ||
        lower.endsWith('.ini') ||
        lower.endsWith('.conf') ||
        lower.endsWith('.yaml') ||
        lower.endsWith('.yml')) {
      return _bytesToUtf8(bytes);
    }

    // Structured text formats
    if (lower.endsWith('.json')) {
      return _extractJson(bytes);
    }

    if (lower.endsWith('.xml') || lower.endsWith('.svg')) {
      return _extractXml(bytes);
    }

    if (lower.endsWith('.html') || lower.endsWith('.htm')) {
      return _extractHtml(bytes);
    }

    if (lower.endsWith('.csv') || lower.endsWith('.tsv')) {
      return _extractCsv(bytes);
    }

    if (lower.endsWith('.rtf')) {
      return _extractRtf(bytes);
    }

    // Office formats
    if (lower.endsWith('.pdf')) {
      return _extractPdf(bytes);
    }

    if (lower.endsWith('.docx')) {
      return _extractDocx(bytes);
    }

    if (lower.endsWith('.pptx')) {
      return _extractPptx(bytes);
    }

    // Code files
    if (lower.endsWith('.dart') ||
        lower.endsWith('.java') ||
        lower.endsWith('.py') ||
        lower.endsWith('.js') ||
        lower.endsWith('.ts') ||
        lower.endsWith('.cpp') ||
        lower.endsWith('.c') ||
        lower.endsWith('.h') ||
        lower.endsWith('.cs') ||
        lower.endsWith('.php') ||
        lower.endsWith('.rb') ||
        lower.endsWith('.go') ||
        lower.endsWith('.rs') ||
        lower.endsWith('.swift') ||
        lower.endsWith('.kt')) {
      return _bytesToUtf8(bytes);
    }

    // Fallback: try UTF-8 decoding
    final text = _bytesToUtf8(bytes);

    // If the text seems valid (mostly printable characters), return it
    if (_isValidText(text)) {
      return text;
    }

    return 'Unsupported file type or binary file. Supported formats: PDF, DOCX, PPTX, TXT, MD, CSV, JSON, XML, HTML, RTF, and code files.';
  }

  /// Check if the decoded text is valid (mostly printable characters)
  static bool _isValidText(String text) {
    if (text.isEmpty || text.length < 10) return false;

    int printableCount = 0;
    int totalCount = min(text.length, 500); // Check first 500 chars

    for (int i = 0; i < totalCount; i++) {
      final code = text.codeUnitAt(i);
      // Count printable ASCII and common Unicode characters
      if ((code >= 32 && code <= 126) || // Printable ASCII
          code == 9 ||
          code == 10 ||
          code == 13 || // Tab, LF, CR
          code >= 128) {
        // Unicode
        printableCount++;
      }
    }

    // If more than 90% printable, it's probably text
    return (printableCount / totalCount) > 0.9;
  }

  static String _bytesToUtf8(Uint8List bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return String.fromCharCodes(bytes);
    }
  }

  static Future<String> _extractPdf(Uint8List bytes) async {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final buffer = StringBuffer();

      // Extract text from each page with improved formatting
      for (int i = 0; i < document.pages.count; i++) {
        final pageText = PdfTextExtractor(
          document,
        ).extractText(startPageIndex: i, endPageIndex: i);

        if (pageText.trim().isNotEmpty) {
          // Advanced text cleaning and normalization
          String cleanedText = pageText
              // Remove excessive whitespace while preserving single newlines
              .replaceAll(RegExp(r'[ \t]+'), ' ')
              // Normalize multiple newlines to double newline (paragraph breaks)
              .replaceAll(RegExp(r'\n{3,}'), '\n\n')
              // Remove spaces before punctuation
              .replaceAll(RegExp(r'\s+([.,;:!?])'), r'$1')
              // Ensure space after punctuation if followed by letter
              .replaceAll(RegExp(r'([.,;:!?])([A-Za-z])'), r'$1 $2')
              // Fix common OCR issues with numbers
              .replaceAll(RegExp(r'(\d)\s+(\d)'), r'$1$2')
              // Remove hyphenation at line breaks
              .replaceAll(RegExp(r'-\n'), '')
              .trim();

          // Add page marker for reference (helpful for multi-page PDFs)
          if (document.pages.count > 1) {
            buffer.writeln('--- Page ${i + 1} ---');
          }
          buffer.writeln(cleanedText);

          if (i < document.pages.count - 1) {
            buffer.writeln(); // Add spacing between pages
          }
        }
      }

      document.dispose();
      final text = buffer.toString().trim();

      if (text.isEmpty) {
        return 'PDF contained no extractable text. This might be an image-based PDF.';
      }

      // Final cleanup - remove any remaining artifacts
      return text
          .replaceAll(RegExp(r'\n\s+\n'), '\n\n')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
    } catch (e) {
      return 'Failed to extract PDF text: $e. The PDF might be corrupted or encrypted.';
    }
  }

  static Future<String> _extractDocx(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docEntry = archive.findFile('word/document.xml');
      if (docEntry == null) return 'Empty DOCX or missing document.xml';

      final xml = utf8.decode(
        docEntry.content as List<int>,
        allowMalformed: true,
      );
      final doc = XmlDocument.parse(xml);
      final buffer = StringBuffer();

      // Extract text from paragraphs with better formatting
      // Get all tables first to identify which paragraphs to skip
      final allTables = doc.findAllElements('w:tbl').toList();
      final tableParagraphs = <XmlElement>{};
      for (final table in allTables) {
        tableParagraphs.addAll(table.findAllElements('w:p'));
      }

      for (final p in doc.findAllElements('w:p')) {
        // Skip paragraphs that are inside tables (we'll process them separately)
        if (!tableParagraphs.contains(p)) {
          final texts = p
              .findAllElements('w:t')
              .map((t) => t.innerText)
              .join('');
          if (texts.trim().isNotEmpty) {
            // Clean up and normalize text, preserve important formatting
            final cleanedText = texts
                .replaceAll(RegExp(r'[ \t]+'), ' ')
                .replaceAll(RegExp(r'\s+([.,;:!?])'), r'$1')
                .trim();
            buffer.writeln(cleanedText);
          }
        }
      }

      // Extract tables with proper formatting
      final tables = allTables;
      if (tables.isNotEmpty) {
        buffer.writeln('\n--- Tables ---');
        for (int tableIdx = 0; tableIdx < tables.length; tableIdx++) {
          final table = tables[tableIdx];
          if (tables.length > 1) {
            buffer.writeln('\nTable ${tableIdx + 1}:');
          }

          for (final row in table.findAllElements('w:tr')) {
            final rowTexts = <String>[];
            for (final cell in row.findAllElements('w:tc')) {
              final cellText = cell
                  .findAllElements('w:t')
                  .map((t) => t.innerText)
                  .join(' ')
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();
              rowTexts.add(cellText.isEmpty ? '-' : cellText);
            }
            if (rowTexts.isNotEmpty) {
              buffer.writeln(rowTexts.join(' | '));
            }
          }
          buffer.writeln();
        }
      }

      // Extract headers and footers
      final headerEntry = archive.findFile('word/header1.xml');
      if (headerEntry != null) {
        try {
          final headerXml = utf8.decode(
            headerEntry.content as List<int>,
            allowMalformed: true,
          );
          final headerDoc = XmlDocument.parse(headerXml);
          final headerText = headerDoc
              .findAllElements('w:t')
              .map((t) => t.innerText)
              .join(' ')
              .trim();
          if (headerText.isNotEmpty) {
            buffer.writeln('\n--- Header ---');
            buffer.writeln(headerText);
          }
        } catch (_) {
          // Ignore header extraction errors
        }
      }

      final result = buffer.toString().trim();
      return result.isEmpty ? 'No text found in DOCX.' : result;
    } catch (e) {
      return 'Failed to extract DOCX: $e. The file might be corrupted.';
    }
  }

  static Future<String> _extractPptx(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final buffer = StringBuffer();
      int slideIndex = 1;

      while (true) {
        final path = 'ppt/slides/slide$slideIndex.xml';
        final entry = archive.findFile(path);
        if (entry == null) break;

        final xml = utf8.decode(
          entry.content as List<int>,
          allowMalformed: true,
        );
        final doc = XmlDocument.parse(xml);

        // Extract slide title (usually in p:sp with placeholder type="ctrTitle" or "title")
        String? slideTitle;
        for (final sp in doc.findAllElements('p:sp')) {
          final phType = sp
              .findElements('p:nvSpPr')
              .expand((nv) => nv.findAllElements('p:ph'))
              .map((ph) => ph.getAttribute('type'))
              .firstWhere(
                (type) => type == 'ctrTitle' || type == 'title',
                orElse: () => null,
              );

          if (phType != null) {
            slideTitle = sp
                .findAllElements('a:t')
                .map((t) => t.innerText.trim())
                .where((t) => t.isNotEmpty)
                .join(' ');
            break;
          }
        }

        // Extract all text content from the slide
        final allTextElements = doc
            .findAllElements('a:t')
            .map((t) => t.innerText.trim())
            .where((t) => t.isNotEmpty)
            .toList();

        // Remove duplicates while preserving order
        final uniqueTexts = <String>[];
        final seen = <String>{};
        for (final text in allTextElements) {
          if (!seen.contains(text)) {
            uniqueTexts.add(text);
            seen.add(text);
          }
        }

        if (uniqueTexts.isNotEmpty) {
          buffer.writeln(
            '--- Slide $slideIndex${slideTitle != null ? ": $slideTitle" : ""} ---',
          );

          // Separate title from content
          if (slideTitle != null && uniqueTexts.isNotEmpty) {
            uniqueTexts.removeWhere((text) => text == slideTitle);
          }

          // Format the content
          for (final text in uniqueTexts) {
            final cleanedText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
            buffer.writeln(cleanedText);
          }
          buffer.writeln();
        }
        slideIndex++;
      }

      // Extract notes if present
      int notesIndex = 1;
      while (true) {
        final notesPath = 'ppt/notesSlides/notesSlide$notesIndex.xml';
        final notesEntry = archive.findFile(notesPath);
        if (notesEntry == null) break;

        try {
          final notesXml = utf8.decode(
            notesEntry.content as List<int>,
            allowMalformed: true,
          );
          final notesDoc = XmlDocument.parse(notesXml);
          final notesText = notesDoc
              .findAllElements('a:t')
              .map((t) => t.innerText.trim())
              .where((t) => t.isNotEmpty)
              .join(' ');

          if (notesText.isNotEmpty) {
            buffer.writeln('--- Slide $notesIndex Notes ---');
            buffer.writeln(notesText);
            buffer.writeln();
          }
        } catch (_) {
          // Ignore notes extraction errors
        }
        notesIndex++;
      }

      final result = buffer.toString().trim();
      return result.isEmpty ? 'No text found in PPTX.' : result;
    } catch (e) {
      return 'Failed to extract PPTX: $e. The file might be corrupted.';
    }
  }

  static Future<String> _extractJson(Uint8List bytes) async {
    try {
      final text = _bytesToUtf8(bytes);
      final json = jsonDecode(text);

      // Pretty print JSON for better readability
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      // If JSON parsing fails, return as plain text
      return _bytesToUtf8(bytes);
    }
  }

  static Future<String> _extractXml(Uint8List bytes) async {
    try {
      final text = _bytesToUtf8(bytes);
      final doc = XmlDocument.parse(text);

      // Extract all text nodes for content
      final buffer = StringBuffer();
      for (final node in doc.descendants) {
        if (node is XmlText) {
          final trimmed = node.value.trim();
          if (trimmed.isNotEmpty) {
            buffer.writeln(trimmed);
          }
        }
      }

      final extracted = buffer.toString().trim();
      return extracted.isNotEmpty ? extracted : text;
    } catch (e) {
      // If XML parsing fails, return as plain text
      return _bytesToUtf8(bytes);
    }
  }

  static Future<String> _extractHtml(Uint8List bytes) async {
    try {
      final html = _bytesToUtf8(bytes);

      // Simple HTML tag removal (basic approach)
      String text = html
          // Remove scripts and styles
          .replaceAll(
            RegExp(
              r'<script[^>]*>.*?</script>',
              caseSensitive: false,
              dotAll: true,
            ),
            '',
          )
          .replaceAll(
            RegExp(
              r'<style[^>]*>.*?</style>',
              caseSensitive: false,
              dotAll: true,
            ),
            '',
          )
          // Remove HTML comments
          .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
          // Replace br and p tags with newlines
          .replaceAll(RegExp(r'<br\s*/?>|</p>', caseSensitive: false), '\n')
          // Remove all other HTML tags
          .replaceAll(RegExp(r'<[^>]*>'), '')
          // Decode common HTML entities
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          // Clean up excessive whitespace
          .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .trim();

      return text.isNotEmpty ? text : html;
    } catch (e) {
      return _bytesToUtf8(bytes);
    }
  }

  static Future<String> _extractCsv(Uint8List bytes) async {
    try {
      final text = _bytesToUtf8(bytes);
      final lines = text.split('\n');
      final buffer = StringBuffer();

      // Format CSV for better readability
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Split by comma (simple approach, doesn't handle quoted commas)
        final cells = line
            .split(',')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty);

        if (i == 0) {
          buffer.writeln('--- Headers ---');
          buffer.writeln(cells.join(' | '));
          buffer.writeln('--- Data ---');
        } else {
          buffer.writeln(cells.join(' | '));
        }
      }

      return buffer.toString().trim().isNotEmpty
          ? buffer.toString().trim()
          : text;
    } catch (e) {
      return _bytesToUtf8(bytes);
    }
  }

  static Future<String> _extractRtf(Uint8List bytes) async {
    try {
      final rtf = _bytesToUtf8(bytes);

      // Basic RTF text extraction (remove control words and groups)
      String text = rtf
          // Remove RTF control words like \rtf1\ansi\deff0
          .replaceAll(RegExp(r'\\[a-z]+(-?\d+)?[ ]?'), ' ')
          // Remove groups (braces and their content if they're control groups)
          .replaceAll(RegExp(r'\{\\[^}]*\}'), '')
          // Remove remaining braces
          .replaceAll(RegExp(r'[{}]'), '')
          // Remove backslash escapes
          .replaceAll(RegExp(r'\\[*]'), '')
          // Clean up whitespace
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      return text.isNotEmpty ? text : rtf;
    } catch (e) {
      return _bytesToUtf8(bytes);
    }
  }
}
