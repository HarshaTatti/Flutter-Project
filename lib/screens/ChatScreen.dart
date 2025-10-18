import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/chat_message.dart';
import 'package:flutter_application_1/services/chatbot_service.dart';
import 'package:flutter_application_1/services/file_text_extractor.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import 'package:path_provider/path_provider.dart';

/// Main chat screen
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatbotService _chatbotService = ChatbotService();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeChatbot();
    _addWelcomeMessage();
  }

  Future<void> _initializeChatbot() async {
    await _chatbotService.initialize();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "👋 **Welcome to Privacy AI Assistant!**\n\n"
              "🔒 **100% Private & Secure**\n"
              "All your data stays on this device - nothing is sent to external servers.\n\n"
              "📄 **Document Support**\n"
              "Upload PDF, DOCX, PPTX, TXT, MD, or CSV files using the + button.\n\n"
              "🤖 **Smart Features**\n"
              "• Intelligent document search and analysis\n"
              "• Natural language queries\n"
              "• Content summarization\n"
              "• Local AI processing\n\n"
              "💡 **Get Started**\n"
              "Upload a document and ask me anything about its content!",
          isUser: false,
        ),
      );
    });
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();

    // Add user message with smooth animation
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });

    _scrollToBottom();

    // Show "thinking" indicator with better UX
    await Future.delayed(const Duration(milliseconds: 200));

    // Add animated thinking indicator message
    final thinkingIndex = _messages.length;
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              '🔍 Searching documents...\n💭 Analyzing context...\n🎯 Finding best answer...',
          isUser: false,
        ),
      );
    });

    _scrollToBottom();

    // Small delay for UX (makes it feel like AI is thinking)
    await Future.delayed(const Duration(milliseconds: 400));

    // Process query locally
    final response = await _chatbotService.processQuery(text);

    // Remove thinking indicator and add real response with smooth transition
    setState(() {
      _messages.removeAt(thinkingIndex); // Remove thinking message
      _messages.add(ChatMessage(text: response, isUser: false));
      _isTyping = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    // Enhanced smooth scrolling with better timing
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 400,
          ), // Slightly longer for smoothness
          curve: Curves.easeOutCubic, // Smoother curve
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology, size: 24, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Privacy AI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          _buildActionButton(
            icon: Icons.add_rounded,
            tooltip: 'Upload Document',
            onPressed: () => _loadDocument(),
          ),
          _buildActionButton(
            icon: Icons.folder_open_rounded,
            tooltip: 'Manage Documents',
            onPressed: () => _showManageDocuments(),
          ),
          _buildActionButton(
            icon: Icons.info_outline_rounded,
            tooltip: 'About',
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Modern privacy banner
            Container(
              margin: const EdgeInsets.only(top: 100, left: 16, right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '100% Local Processing • No Data Sent to Servers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Chat messages
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Chat header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Color(0xFF6366F1),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Chat',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Messages
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessage(_messages[index]);
                        },
                      ),
                    ),
                    // Typing indicator
                    if (_isTyping)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Processing locally...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Input field
                    _buildTextComposer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.isUser;
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          if (!isUser) const SizedBox(width: 12),
          Flexible(
            child: IntrinsicWidth(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                  minWidth: 80,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        )
                      : null,
                  color: isUser ? null : Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isUser ? const Color(0xFF6366F1) : Colors.grey)
                          .withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isUser
                        ? Colors.transparent
                        : Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectableText(
                      _formatMessageText(message.text),
                      style: TextStyle(
                        color: isUser ? Colors.white : const Color(0xFF1F2937),
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: isUser ? Colors.white70 : Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (message.text.length > 100)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (isUser ? Colors.white : Colors.grey[200])
                                  ?.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${message.text.split(' ').length} words',
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white70
                                    : Colors.grey[600],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ), // Column
              ), // Container
            ), // IntrinsicWidth
          ), // Flexible
          if (isUser) const SizedBox(width: 12),
          if (isUser)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  /// Format message text to improve readability
  String _formatMessageText(String text) {
    // Clean up excessive whitespace and normalize line breaks
    String formatted = text
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        ) // Replace multiple spaces with single space
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n') // Max 2 line breaks
        .trim();

    // Add proper spacing after punctuation if missing
    formatted = formatted
        .replaceAll(RegExp(r'\.([A-Z])'), '. \$1')
        .replaceAll(RegExp(r'\,([A-Z])'), ', \$1')
        .replaceAll(RegExp(r'\:([A-Z])'), ': \$1');

    // Handle bullet points and lists
    formatted = formatted
        .replaceAll(RegExp(r'\s*-\s+'), '\n• ')
        .replaceAll(RegExp(r'\s*\*\s+'), '\n• ');

    // Handle numbered lists
    formatted = formatted.replaceAllMapped(
      RegExp(r'(\d+)\.\s+'),
      (match) => '\n${match.group(1)}. ',
    );

    // Clean up again after transformations
    formatted = formatted
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
        .replaceAll(RegExp(r'^\n+'), '')
        .replaceAll(RegExp(r'\n+$'), '')
        .trim();

    return formatted;
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration(
                  hintText: 'Ask me anything about your documents...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Icon(
                      Icons.search_rounded,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                  ),
                ),
                style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8FAFC)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Privacy Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection(
                      '🔒 Complete Privacy',
                      '• All data is stored locally on your device\n'
                          '• No external servers or APIs are contacted\n'
                          '• No internet connection required for queries\n'
                          '• All processing happens on your device\n'
                          '• Your data never leaves your device',
                    ),
                    const SizedBox(height: 20),
                    _buildInfoSection(
                      '💡 How it works',
                      '• Data is stored using SharedPreferences\n'
                          '• Advanced AI processing for document search\n'
                          '• Chunked indexing for better accuracy\n'
                          '• Simple and transparent processing',
                    ),
                    const SizedBox(height: 20),
                    _buildInfoSection(
                      '📱 Data Storage',
                      'Currently storing sample data. In a production app, '
                          'you would add your own personal information through a '
                          'settings screen.',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Got it!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }

  /// Load document from device
  Future<void> _loadDocument() async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'csv', 'pdf', 'docx', 'pptx'],
        allowMultiple: false,
        withData: true, // Important for web!
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final fileName = pickedFile.name;

        // Show loading
        if (mounted) {
          setState(() {
            _isTyping = true;
            _messages.add(
              ChatMessage(
                text: "Loading document: $fileName...",
                isUser: false,
              ),
            );
          });
          _scrollToBottom();
        }

        // Read file content using offline extractor (supports txt, md, csv, pdf, docx, pptx)
        String content;
        String? savedPath;
        int? sizeBytes;
        if (pickedFile.bytes != null) {
          content = await FileTextExtractor.extractText(
            fileName: fileName,
            bytes: pickedFile.bytes!,
          );
          // Persist extracted text as .txt for consistent behavior
          try {
            final dir = await getApplicationDocumentsDirectory();
            final baseName = fileName.contains('.')
                ? fileName.substring(0, fileName.lastIndexOf('.'))
                : fileName;
            final safeName = baseName.replaceAll(
              RegExp(r'[^A-Za-z0-9._-]+'),
              '_',
            );
            final target = File('${dir.path}/$safeName.txt');
            await target.writeAsString(content);
            savedPath = target.path;
            sizeBytes = await target.length();
          } catch (_) {}
        } else if (pickedFile.path != null) {
          // Fallback if bytes are missing (should be rare with withData: true)
          final file = File(pickedFile.path!);
          final bytes = await file.readAsBytes();
          content = await FileTextExtractor.extractText(
            fileName: fileName,
            bytes: bytes,
          );
          // Save normalized .txt copy
          try {
            final dir = await getApplicationDocumentsDirectory();
            final baseName = fileName.contains('.')
                ? fileName.substring(0, fileName.lastIndexOf('.'))
                : fileName;
            final safeName = baseName.replaceAll(
              RegExp(r'[^A-Za-z0-9._-]+'),
              '_',
            );
            final target = File('${dir.path}/$safeName.txt');
            await target.writeAsString(content);
            savedPath = target.path;
            sizeBytes = await target.length();
          } catch (_) {}
        } else {
          content = 'Error: No file data available';
        }

        // Add to document service (LOCAL PROCESSING)
        await _chatbotService.documentService.addDocument(
          fileName,
          content,
          filePath: savedPath,
          sizeBytes: sizeBytes,
        );

        // Show success message
        if (mounted) {
          setState(() {
            _isTyping = false;
            final wordCount = content.split(' ').length;
            final charCount = content.length;
            final fileType = fileName.split('.').last.toUpperCase();

            _messages.add(
              ChatMessage(
                text:
                    "✅ **$fileType Document Loaded Successfully!**\n\n"
                    "📄 **File:** $fileName\n"
                    "📊 **Content:** $wordCount words, $charCount characters\n"
                    "🔍 **Status:** Indexed and ready for queries\n\n"
                    "💡 **Try asking:**\n"
                    "• \"What is this document about?\"\n"
                    "• \"Summarize the main points\"\n"
                    "• \"Find information about [topic]\"",
                isUser: false,
              ),
            );
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text:
                  "❌ Error loading document: $e\n\nTip: Supported: .txt, .md, .csv, .pdf, .docx, .pptx",
              isUser: false,
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  void _showManageDocuments() {
    final docs = _chatbotService.documentService.getDocuments();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Manage Documents'),
          content: SizedBox(
            width: double.maxFinite,
            child: docs.isEmpty
                ? const Text('No documents loaded.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final d = docs[i];
                      return ListTile(
                        title: Text(
                          d.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (d.filePath != null)
                              Text(
                                d.filePath!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    d.name.split('.').last.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${d.content.split(' ').length} words',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _chatbotService.documentService
                                .deleteDocumentAndFile(d.id);
                            if (mounted) {
                              setState(() {});
                            }
                            _messages.add(
                              ChatMessage(
                                text: "🗑️ Deleted '${d.name}'",
                                isUser: false,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (docs.isNotEmpty)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Delete all: remove files where present
                  for (final d in List.of(docs)) {
                    await _chatbotService.documentService.deleteDocumentAndFile(
                      d.id,
                    );
                  }
                  if (mounted) setState(() {});
                  _messages.add(
                    ChatMessage(
                      text: '🧹 All documents deleted',
                      isUser: false,
                    ),
                  );
                },
                child: const Text('Delete All'),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
