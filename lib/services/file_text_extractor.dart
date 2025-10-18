import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Lightweight offline extractor to convert common office files to plain text
class FileTextExtractor {
  /// Detect file type from name and delegate extraction
  static Future<String> extractText({required String fileName, required Uint8List bytes}) async {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.txt') || lower.endsWith('.md') || lower.endsWith('.csv')) {
      return _bytesToUtf8(bytes);
    }
    if (lower.endsWith('.pdf')) {
      return _extractPdf(bytes);
    }
    if (lower.endsWith('.docx')) {
      return _extractDocx(bytes);
    }
    if (lower.endsWith('.pptx')) {
      return _extractPptx(bytes);
    }
    // Fallback: try UTF-8
    return _bytesToUtf8(bytes);
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
      
      for (int i = 0; i < document.pages.count; i++) {
        final pageText = PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        if (pageText.trim().isNotEmpty) {
          // Clean up the text - remove excessive whitespace and normalize
          final cleanedText = pageText
              .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
              .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Normalize line breaks
              .trim();
          buffer.writeln(cleanedText);
        }
      }
      
      document.dispose();
      final text = buffer.toString().trim();
      return text.isEmpty ? 'PDF contained no extractable text.' : text;
    } catch (e) {
      return 'Failed to extract PDF text: $e';
    }
  }

  static Future<String> _extractDocx(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docEntry = archive.findFile('word/document.xml');
      if (docEntry == null) return 'Empty DOCX or missing document.xml';
      
      final xml = utf8.decode(docEntry.content as List<int>, allowMalformed: true);
      final doc = XmlDocument.parse(xml);
      final buffer = StringBuffer();
      
      // Extract text from paragraphs with better formatting
      for (final p in doc.findAllElements('w:p')) {
        final texts = p.findAllElements('w:t').map((t) => t.innerText).join('');
        if (texts.trim().isNotEmpty) {
          // Clean up and normalize text
          final cleanedText = texts
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          buffer.writeln(cleanedText);
        }
      }
      
      // Also try to extract from tables
      for (final table in doc.findAllElements('w:tbl')) {
        for (final row in table.findAllElements('w:tr')) {
          final rowTexts = <String>[];
          for (final cell in row.findAllElements('w:tc')) {
            final cellText = cell.findAllElements('w:t').map((t) => t.innerText).join(' ').trim();
            if (cellText.isNotEmpty) rowTexts.add(cellText);
          }
          if (rowTexts.isNotEmpty) {
            buffer.writeln(rowTexts.join(' | '));
          }
        }
      }
      
      final result = buffer.toString().trim();
      return result.isEmpty ? 'No text found in DOCX.' : result;
    } catch (e) {
      return 'Failed to extract DOCX: $e';
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
        
        final xml = utf8.decode(entry.content as List<int>, allowMalformed: true);
        final doc = XmlDocument.parse(xml);
        
        // Extract text from a:t elements (text boxes)
        final texts = doc.findAllElements('a:t')
            .map((t) => t.innerText.trim())
            .where((t) => t.isNotEmpty)
            .toList();
            
        // Also extract from p:txBody elements (slide content)
        final slideTexts = doc.findAllElements('p:txBody')
            .expand((txBody) => txBody.findAllElements('a:t'))
            .map((t) => t.innerText.trim())
            .where((t) => t.isNotEmpty)
            .toList();
            
        final allTexts = <dynamic>{...texts, ...slideTexts}.toList(); // Remove duplicates
        
        if (allTexts.isNotEmpty) {
          buffer.writeln('--- Slide $slideIndex ---');
          buffer.writeln(allTexts.join('\n'));
          buffer.writeln();
        }
        slideIndex++;
      }
      
      final result = buffer.toString().trim();
      return result.isEmpty ? 'No text found in PPTX.' : result;
    } catch (e) {
      return 'Failed to extract PPTX: $e';
    }
  }
}

