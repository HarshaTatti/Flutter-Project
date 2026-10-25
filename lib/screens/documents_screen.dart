import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/document.dart';
import '../services/document_service.dart';
import '../services/file_text_extractor.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_nav_scaffold.dart';

/// Document management screen with in-memory upload, text extraction, inspection, and removal
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final DocumentService _documentService = DocumentService();
  bool _isLoading = true;
  bool _isProcessing = false;
  String _searchFilter = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    await _documentService.loadDocuments();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'csv', 'pdf', 'docx', 'pptx'],
        allowMultiple: false,
        withData: true, // Needed for Web
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final Uint8List? bytes = file.bytes;

        if (bytes == null || bytes.isEmpty) {
          _showSnackBar('Selected file has no data or cannot be read.', isError: true);
          return;
        }

        setState(() => _isProcessing = true);

        // Real text extraction using pure Dart offline extractor
        final extractedText = await FileTextExtractor.extractText(
          fileName: file.name,
          bytes: bytes,
        );

        if (extractedText.isEmpty) {
          _showSnackBar('No readable text could be extracted from this file.', isError: true);
          setState(() => _isProcessing = false);
          return;
        }

        // Add document to local DocumentService (rebuilds TF-IDF index locally)
        await _documentService.addDocument(
          file.name,
          extractedText,
          sizeBytes: file.size,
        );

        if (mounted) {
          setState(() => _isProcessing = false);
          final wordCount = extractedText.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
          _showSnackBar(
            'Successfully loaded "${file.name}" ($wordCount words indexed)',
            isError: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnackBar('Error loading document: $e', isError: true);
      }
    }
  }

  Future<void> _deleteDocument(Document doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isHighContrast =
            Provider.of<ThemeController>(context, listen: false).isHighContrast;

        return AlertDialog(
          title: Text(
            'Delete Document',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighContrast ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${doc.name}" from local storage?',
            style: TextStyle(
              color: isHighContrast ? Colors.white : colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _documentService.deleteDocumentAndFile(doc.id);
      if (mounted) {
        setState(() {});
        _showSnackBar('Document "${doc.name}" deleted.');
      }
    }
  }

  Future<void> _clearAllDocuments() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isHighContrast =
            Provider.of<ThemeController>(context, listen: false).isHighContrast;

        return AlertDialog(
          title: Text(
            'Clear All Documents',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighContrast ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          content: Text(
            'This will permanently delete all uploaded documents and indices from local storage.',
            style: TextStyle(
              color: isHighContrast ? Colors.white : colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _documentService.clearAllDocuments();
      if (mounted) {
        setState(() {});
        _showSnackBar('All documents deleted.');
      }
    }
  }

  void _showDocumentPreview(Document doc) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isHighContrast =
            Provider.of<ThemeController>(context, listen: false).isHighContrast;
        final wordCount = doc.content.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;

        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          doc.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isHighContrast ? colorScheme.primary : colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      Text(
                        'Words: $wordCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isHighContrast ? Colors.white : colorScheme.outline,
                        ),
                      ),
                      Text(
                        'Characters: ${doc.content.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isHighContrast ? Colors.white : colorScheme.outline,
                        ),
                      ),
                      Text(
                        'Uploaded: ${DateFormat('yyyy-MM-dd HH:mm').format(doc.loadedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isHighContrast ? Colors.white : colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    color: isHighContrast ? colorScheme.primary : colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isHighContrast
                            ? Colors.black
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isHighContrast
                              ? colorScheme.secondary
                              : colorScheme.outlineVariant,
                          width: isHighContrast ? 2.0 : 1.0,
                        ),
                      ),
                      child: SelectableText(
                        doc.content,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.55,
                          fontFamily: 'monospace',
                          color: isHighContrast ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushReplacementNamed(
                            '/chat',
                            arguments: 'What is ${doc.name} about?',
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text('Ask in Chat'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHighContrast =
        Provider.of<ThemeController>(context, listen: false).isHighContrast;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isHighContrast ? Colors.black : Colors.white,
          ),
        ),
        backgroundColor: isHighContrast
            ? (isError ? colorScheme.error : colorScheme.primary)
            : (isError ? colorScheme.error : const Color(0xFF10B981)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return 'In-Memory';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeController = Provider.of<ThemeController>(context);
    final isHighContrast = themeController.isHighContrast;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    final allDocs = _documentService.getDocuments();
    final filteredDocs = _searchFilter.trim().isEmpty
        ? allDocs
        : allDocs.where((d) {
            final q = _searchFilter.toLowerCase();
            return d.name.toLowerCase().contains(q) ||
                d.content.toLowerCase().contains(q);
          }).toList();

    return AppNavScaffold(
      currentRoute: AppRoute.documents,
      actions: [
        if (allDocs.isNotEmpty)
          IconButton(
            tooltip: 'Clear All Documents',
            icon: Icon(
              Icons.delete_sweep_rounded,
              color: isHighContrast ? colorScheme.primary : colorScheme.onSurface,
            ),
            onPressed: _clearAllDocuments,
          ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 20,
                vertical: isDesktop ? 40 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Document Management',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 32 : 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: isHighContrast
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload and index local documents for offline semantic search and querying.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isHighContrast
                                        ? const Color(0xFFDDDDDD)
                                        : colorScheme.onSurface.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _pickAndUploadDocument,
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.upload_file_rounded),
                            label: Text(_isProcessing ? 'Processing...' : 'Upload File'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Supported Formats Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isHighContrast
                              ? Colors.black
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isHighContrast
                                ? colorScheme.secondary
                                : colorScheme.outlineVariant,
                            width: isHighContrast ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: isHighContrast
                                  ? colorScheme.secondary
                                  : colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Supported formats: PDF, DOCX, PPTX, TXT, Markdown (.md), and CSV. All extracted 100% locally.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isHighContrast
                                      ? Colors.white
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Search filter bar
                      if (allDocs.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) => setState(() => _searchFilter = val),
                                decoration: InputDecoration(
                                  hintText: 'Search within uploaded documents...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _searchFilter.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchFilter = '');
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isHighContrast
                                    ? Colors.black
                                    : colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isHighContrast
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant,
                                  width: isHighContrast ? 2.0 : 1.0,
                                ),
                              ),
                              child: Text(
                                '${filteredDocs.length} ${filteredDocs.length == 1 ? 'doc' : 'docs'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isHighContrast ? Colors.white : colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Document List or Empty State
                      if (allDocs.isEmpty)
                        _buildEmptyUploadZone(isHighContrast, colorScheme)
                      else if (filteredDocs.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Text(
                            'No documents matching "$_searchFilter"',
                            style: TextStyle(
                              fontSize: 16,
                              color: isHighContrast ? Colors.white : colorScheme.outline,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredDocs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _buildDocumentCard(
                              filteredDocs[index],
                              isHighContrast,
                              colorScheme,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyUploadZone(bool isHighContrast, ColorScheme colorScheme) {
    return InkWell(
      onTap: _pickAndUploadDocument,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
        decoration: BoxDecoration(
          color: isHighContrast ? Colors.black : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighContrast ? colorScheme.primary : colorScheme.outlineVariant,
            width: isHighContrast ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isHighContrast
                    ? Colors.black
                    : colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: isHighContrast
                    ? Border.all(color: colorScheme.primary, width: 2.0)
                    : null,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: isHighContrast ? colorScheme.primary : colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Documents Uploaded Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isHighContrast ? Colors.white : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click to upload PDF, DOCX, PPTX, TXT, MD, or CSV files from your device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isHighContrast
                    ? const Color(0xFFDDDDDD)
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickAndUploadDocument,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Select File to Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(
    Document doc,
    bool isHighContrast,
    ColorScheme colorScheme,
  ) {
    final ext = doc.name.contains('.') ? doc.name.split('.').last.toUpperCase() : 'TXT';
    final wordCount = doc.content.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    final formattedDate = DateFormat('MMM d, yyyy • HH:mm').format(doc.loadedAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Extension Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isHighContrast
                    ? Colors.black
                    : colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isHighContrast ? colorScheme.primary : colorScheme.primary,
                  width: isHighContrast ? 2.0 : 1.0,
                ),
              ),
              child: Text(
                ext,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isHighContrast ? colorScheme.primary : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 18),

            // Document Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isHighContrast ? Colors.white : colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storage_rounded,
                            size: 13,
                            color: isHighContrast
                                ? const Color(0xFFDDDDDD)
                                : colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatBytes(doc.sizeBytes),
                            style: TextStyle(
                              fontSize: 12,
                              color: isHighContrast
                                  ? const Color(0xFFDDDDDD)
                                  : colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.short_text_rounded,
                            size: 14,
                            color: isHighContrast
                                ? const Color(0xFFDDDDDD)
                                : colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$wordCount words',
                            style: TextStyle(
                              fontSize: 12,
                              color: isHighContrast
                                  ? const Color(0xFFDDDDDD)
                                  : colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: isHighContrast
                                ? const Color(0xFFDDDDDD)
                                : colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: isHighContrast
                                  ? const Color(0xFFDDDDDD)
                                  : colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Buttons
            Wrap(
              spacing: 8,
              children: [
                IconButton(
                  tooltip: 'Preview Extracted Content',
                  icon: Icon(
                    Icons.visibility_outlined,
                    color: isHighContrast ? colorScheme.secondary : colorScheme.primary,
                  ),
                  onPressed: () => _showDocumentPreview(doc),
                ),
                IconButton(
                  tooltip: 'Ask about this document',
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: colorScheme.primary,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(
                      '/chat',
                      arguments: 'What is ${doc.name} about?',
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Delete Document',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colorScheme.error,
                  ),
                  onPressed: () => _deleteDocument(doc),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
