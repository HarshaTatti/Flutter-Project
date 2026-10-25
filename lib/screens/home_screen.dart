import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_nav_scaffold.dart';
import '../widgets/feature_card.dart';

/// Homepage for the Privacy-Preserving Chatbot web application
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeController = Provider.of<ThemeController>(context);
    final isHighContrast = themeController.isHighContrast;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    return AppNavScaffold(
      currentRoute: AppRoute.home,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: isHighContrast
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: themeController.isDark
                            ? [
                                const Color(0xFF0F172A),
                                const Color(0xFF1E1B4B),
                                const Color(0xFF0F172A),
                              ]
                            : [
                                const Color(0xFFEEF2FF),
                                const Color(0xFFF5F3FF),
                                const Color(0xFFF8FAFC),
                              ],
                      ),
                color: isHighContrast ? Colors.black : null,
                border: Border(
                  bottom: BorderSide(
                    color: isHighContrast
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    width: isHighContrast ? 2.5 : 1.0,
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 24,
                vertical: isDesktop ? 64 : 40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: [
                      // Privacy Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isHighContrast
                              ? Colors.black
                              : colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isHighContrast
                                ? colorScheme.secondary
                                : colorScheme.primary.withValues(alpha: 0.3),
                            width: isHighContrast ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 16,
                              color: isHighContrast
                                  ? colorScheme.secondary
                                  : colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '100% Client-Side Privacy • Zero External APIs',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isHighContrast
                                    ? colorScheme.secondary
                                    : colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Main Hero Heading
                      Text(
                        'Intelligent AI Assistance,\nCompletely Private.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isDesktop ? 48 : 32,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.8,
                          color: isHighContrast ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Subheading
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Text(
                          'Ask questions, search multi-format documents, and inspect personal information with a powerful on-device NLP engine. No cloud servers, no tracking, and no data leaks.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isDesktop ? 18 : 15,
                            height: 1.6,
                            color: isHighContrast
                                ? const Color(0xFFDDDDDD)
                                : colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/chat');
                            },
                            icon: const Icon(Icons.chat_bubble_rounded),
                            label: const Text('Start Chatting'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 32 : 24,
                                vertical: isDesktop ? 18 : 16,
                              ),
                              textStyle: TextStyle(
                                fontSize: isDesktop ? 16 : 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/documents');
                            },
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('Manage Documents'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 32 : 24,
                                vertical: isDesktop ? 18 : 16,
                              ),
                              textStyle: TextStyle(
                                fontSize: isDesktop ? 16 : 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Feature Cards Grid Section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 24,
                vertical: isDesktop ? 64 : 40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Core Capabilities',
                        style: TextStyle(
                          fontSize: isDesktop ? 28 : 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isHighContrast ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Built from the ground up for strict privacy, accessibility, and high performance.',
                        style: TextStyle(
                          fontSize: 15,
                          color: isHighContrast
                              ? const Color(0xFFDDDDDD)
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Features Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 900
                              ? 2
                              : 1;

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: columns,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: columns == 2 ? 1.65 : 1.35,
                            children: [
                              FeatureCard(
                                icon: Icons.lock_outline_rounded,
                                title: 'Privacy-First Architecture',
                                description:
                                    'Zero cloud requests. All document indexing, text tokenization, and queries execute entirely on your device with local storage.',
                                badgeText: '100% OFFLINE',
                                accentColor: const Color(0xFF10B981),
                                onTap: () => Navigator.of(context).pushReplacementNamed('/settings'),
                              ),
                              FeatureCard(
                                icon: Icons.description_outlined,
                                title: 'Secure Document Handling',
                                description:
                                    'Load files directly into memory. Index documents without sending copies to remote servers or third-party AI providers.',
                                badgeText: 'LOCAL STORAGE',
                                accentColor: const Color(0xFF6366F1),
                                onTap: () => Navigator.of(context).pushReplacementNamed('/documents'),
                              ),
                              FeatureCard(
                                icon: Icons.text_snippet_outlined,
                                title: 'Multi-Format Text Extraction',
                                description:
                                    'Native client-side parsing for PDF, DOCX, PPTX, TXT, Markdown, and CSV files with zero external cloud dependencies.',
                                badgeText: '6+ FORMATS',
                                accentColor: const Color(0xFFF59E0B),
                                onTap: () => Navigator.of(context).pushReplacementNamed('/documents'),
                              ),
                              FeatureCard(
                                icon: Icons.psychology_outlined,
                                title: 'Intelligent Semantic Responses',
                                description:
                                    'Fast TF-IDF vector ranking, intent classification, and entity recognition providing transparent answers with source citations.',
                                badgeText: '<20MS LATENCY',
                                accentColor: const Color(0xFFEC4899),
                                onTap: () => Navigator.of(context).pushReplacementNamed('/chat'),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sample Queries Section
            Container(
              width: double.infinity,
              color: isHighContrast
                  ? Colors.black
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 24,
                vertical: isDesktop ? 48 : 36,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Try Asking These Sample Questions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isHighContrast ? Colors.white : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          _buildQueryChip(
                            context,
                            'What is my name?',
                            isHighContrast,
                          ),
                          _buildQueryChip(
                            context,
                            'Tell me my email address',
                            isHighContrast,
                          ),
                          _buildQueryChip(
                            context,
                            'What can you do?',
                            isHighContrast,
                          ),
                          _buildQueryChip(
                            context,
                            'How many documents are loaded?',
                            isHighContrast,
                          ),
                          _buildQueryChip(
                            context,
                            'Summarize my documents',
                            isHighContrast,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildQueryChip(
    BuildContext context,
    String query,
    bool isHighContrast,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ActionChip(
      avatar: Icon(
        Icons.chat_bubble_outline_rounded,
        size: 15,
        color: isHighContrast ? colorScheme.primary : colorScheme.primary,
      ),
      label: Text(query),
      backgroundColor: isHighContrast ? Colors.black : colorScheme.surface,
      side: BorderSide(
        color: isHighContrast ? colorScheme.primary : colorScheme.outlineVariant,
        width: isHighContrast ? 2.0 : 1.0,
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isHighContrast ? Colors.white : colorScheme.onSurface,
      ),
      onPressed: () {
        Navigator.of(context).pushReplacementNamed('/chat', arguments: query);
      },
    );
  }
}
