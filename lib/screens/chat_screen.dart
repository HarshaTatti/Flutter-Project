import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../services/chatbot_service.dart';
import '../services/file_text_extractor.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_nav_scaffold.dart';

/// Full-featured, responsive, theme-aware Chat Screen
class ChatScreen extends StatefulWidget {
  final String? initialQuery;

  const ChatScreen({super.key, this.initialQuery});

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
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _chatbotService.initialize();
    _addWelcomeMessage();

    // Check for initial query passed from home screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialQuery = widget.initialQuery ??
          (ModalRoute.of(context)?.settings.arguments as String?);
      if (initialQuery != null && initialQuery.isNotEmpty) {
        _handleSubmitted(initialQuery);
      }
    });
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text: "👋 **Welcome to Privacy AI Assistant!**\n\n"
              "🔒 **100% Client-Side & Private**\n"
              "All processing and document indexing runs strictly inside this device. No servers, no tracking.\n\n"
              "📄 **Document Support**\n"
              "Upload PDF, DOCX, PPTX, TXT, MD, or CSV files to question them.\n\n"
              "💡 **Try Asking:**\n"
              "• \"What is my name?\"\n"
              "• \"What can you do?\"\n"
              "• \"Search documents for [topic]\"\n"
              "• \"How many documents are loaded?\"",
          isUser: false,
        ),
      );
    });
  }

  void _handleSubmitted(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: trimmed, isUser: true));
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await _chatbotService.processQuery(trimmed);

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: response, isUser: false));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: "⚠️ Sorry, an error occurred while processing: $e",
              isUser: false,
            ),
          );
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isHighContrast =
            Provider.of<ThemeController>(context, listen: false).isHighContrast;

        return AlertDialog(
          title: Text(
            'Clear Conversation',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighContrast ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to clear all chat messages in this session?',
            style: TextStyle(
              color: isHighContrast ? Colors.white : colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _messages.clear();
                  _addWelcomeMessage();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Clear Chat'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadDocumentDirect() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'csv', 'pdf', 'docx', 'pptx'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final fileName = pickedFile.name;
        final Uint8List? bytes = pickedFile.bytes;

        if (bytes == null || bytes.isEmpty) {
          throw Exception('File data is empty or could not be read.');
        }

        if (mounted) {
          setState(() {
            _isTyping = true;
            _messages.add(
              ChatMessage(
                text: "📥 Processing document: **$fileName**...",
                isUser: false,
              ),
            );
          });
          _scrollToBottom();
        }

        final extractedText = await FileTextExtractor.extractText(
          fileName: fileName,
          bytes: bytes,
        );

        await _chatbotService.documentService.addDocument(
          fileName,
          extractedText,
          sizeBytes: pickedFile.size,
        );

        if (mounted) {
          final wordCount = extractedText.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
          setState(() {
            _isTyping = false;
            _messages.add(
              ChatMessage(
                text: "✅ **$fileName** loaded successfully!\n\n"
                    "📊 **Indexed:** $wordCount words\n"
                    "🔒 **Processing:** 100% in-browser memory\n\n"
                    "💡 You can now ask questions about this document!",
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
              text: "❌ Failed to load document: $e\n\n"
                  "Supported formats: .txt, .md, .csv, .pdf, .docx, .pptx",
              isUser: false,
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeController = Provider.of<ThemeController>(context);
    final isHighContrast = themeController.isHighContrast;

    return AppNavScaffold(
      currentRoute: AppRoute.chat,
      actions: [
        IconButton(
          tooltip: 'Clear Chat',
          icon: Icon(
            Icons.delete_outline_rounded,
            color: isHighContrast ? colorScheme.primary : colorScheme.onSurface,
          ),
          onPressed: _clearChat,
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // Privacy info banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? Colors.black
                      : (themeController.isDark
                          ? colorScheme.surface
                          : colorScheme.primaryContainer.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHighContrast
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    width: isHighContrast ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 18,
                      color: isHighContrast ? colorScheme.secondary : colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Offline Mode Active • In-Browser Intelligence • Zero Telemetry',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isHighContrast ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _uploadDocumentDirect,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_file_rounded,
                              size: 15,
                              color: isHighContrast ? colorScheme.primary : colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Attach Doc',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isHighContrast ? colorScheme.primary : colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Chat Messages List
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Say hello!',
                          style: TextStyle(
                            color: isHighContrast ? Colors.white : colorScheme.outline,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageItem(_messages[index], isHighContrast, colorScheme);
                        },
                      ),
              ),

              // Typing indicator
              if (_isTyping)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Processing query locally...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isHighContrast
                              ? colorScheme.secondary
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

              // Quick Question Suggestions
              Container(
                height: 42,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildSuggestionChip('What is my name?', isHighContrast, colorScheme),
                    _buildSuggestionChip('What can you do?', isHighContrast, colorScheme),
                    _buildSuggestionChip('List my documents', isHighContrast, colorScheme),
                    _buildSuggestionChip('Tell me my phone number', isHighContrast, colorScheme),
                    _buildSuggestionChip('Help with commands', isHighContrast, colorScheme),
                  ],
                ),
              ),

              // Input bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isHighContrast ? Colors.black : colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: isHighContrast
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: isHighContrast ? 2.5 : 1.0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Document upload shortcut button
                    IconButton(
                      tooltip: 'Upload Document (.pdf, .docx, .txt, etc.)',
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        color: colorScheme.primary,
                        size: 26,
                      ),
                      onPressed: _uploadDocumentDirect,
                    ),
                    const SizedBox(width: 8),

                    // Input Text Field
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        onSubmitted: _handleSubmitted,
                        style: TextStyle(
                          fontSize: 15,
                          color: isHighContrast ? Colors.white : colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask a question or search documents...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Send Button
                    ElevatedButton(
                      onPressed: () => _handleSubmitted(_textController.text),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isHighContrast
                              ? const BorderSide(color: Colors.white, width: 2)
                              : BorderSide.none,
                        ),
                      ),
                      child: const Icon(Icons.send_rounded, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isHighContrast, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text),
        backgroundColor: isHighContrast ? Colors.black : colorScheme.surface,
        side: BorderSide(
          color: isHighContrast ? colorScheme.primary : colorScheme.outlineVariant,
          width: isHighContrast ? 1.5 : 1.0,
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isHighContrast ? Colors.white : colorScheme.onSurface,
        ),
        onPressed: () => _handleSubmitted(text),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message, bool isHighContrast, ColorScheme colorScheme) {
    final isUser = message.isUser;
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    // Bubble styling based on theme
    final bubbleColor = isUser
        ? (isHighContrast ? Colors.black : colorScheme.primary)
        : (isHighContrast ? Colors.black : colorScheme.surface);

    final borderColor = isUser
        ? (isHighContrast ? colorScheme.primary : Colors.transparent)
        : (isHighContrast ? colorScheme.secondary : colorScheme.outlineVariant);

    final textColor = isUser
        ? (isHighContrast ? colorScheme.primary : colorScheme.onPrimary)
        : (isHighContrast ? Colors.white : colorScheme.onSurface);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isHighContrast ? Colors.black : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: isHighContrast
                    ? Border.all(color: colorScheme.secondary, width: 2)
                    : null,
              ),
              child: Icon(
                Icons.psychology_rounded,
                size: 18,
                color: isHighContrast ? colorScheme.secondary : colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 680),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: borderColor,
                  width: isHighContrast ? 2.5 : 1.0,
                ),
                boxShadow: isHighContrast
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.55,
                      color: textColor,
                      fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isUser
                              ? (isHighContrast
                                  ? colorScheme.primary
                                  : colorScheme.onPrimary.withValues(alpha: 0.75))
                              : (isHighContrast
                                  ? const Color(0xFFBBBBBB)
                                  : colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isUser ? 'You' : 'Local AI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isUser
                              ? (isHighContrast
                                  ? colorScheme.primary
                                  : colorScheme.onPrimary.withValues(alpha: 0.75))
                              : (isHighContrast
                                  ? colorScheme.secondary
                                  : colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isHighContrast ? Colors.black : colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
                border: isHighContrast
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : null,
              ),
              child: Icon(
                Icons.person_rounded,
                size: 18,
                color: isHighContrast ? colorScheme.primary : Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
