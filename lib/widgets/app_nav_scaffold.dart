import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_controller.dart';
import 'theme_switcher.dart';

/// Navigation items
enum AppRoute {
  home,
  chat,
  documents,
  settings,
}

extension AppRouteExtension on AppRoute {
  String get title {
    switch (this) {
      case AppRoute.home:
        return 'Home';
      case AppRoute.chat:
        return 'Chatbot';
      case AppRoute.documents:
        return 'Documents';
      case AppRoute.settings:
        return 'Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case AppRoute.home:
        return Icons.home_rounded;
      case AppRoute.chat:
        return Icons.chat_bubble_rounded;
      case AppRoute.documents:
        return Icons.folder_rounded;
      case AppRoute.settings:
        return Icons.settings_rounded;
    }
  }

  String get routePath {
    switch (this) {
      case AppRoute.home:
        return '/';
      case AppRoute.chat:
        return '/chat';
      case AppRoute.documents:
        return '/documents';
      case AppRoute.settings:
        return '/settings';
    }
  }
}

/// Unified responsive scaffold with persistent AppBar, Navigation, and Theme Switcher
class AppNavScaffold extends StatelessWidget {
  final AppRoute currentRoute;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showFooter;

  const AppNavScaffold({
    super.key,
    required this.currentRoute,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showFooter = true,
  });

  void _navigateTo(BuildContext context, AppRoute route) {
    if (route == currentRoute) return;
    Navigator.of(context).pushReplacementNamed(route.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeController = Provider.of<ThemeController>(context);
    final isHighContrast = themeController.isHighContrast;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1050;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: InkWell(
          onTap: () => _navigateTo(context, AppRoute.home),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isHighContrast ? Colors.black : colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: isHighContrast
                        ? Border.all(color: colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    color: isHighContrast ? colorScheme.primary : Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    screenWidth >= 700 ? 'Privacy-Preserving Chatbot' : 'Privacy Chatbot',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isHighContrast ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Desktop Navigation Links
          if (isDesktop) ...[
            ...AppRoute.values.map((route) {
              final isSelected = route == currentRoute;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: TextButton.icon(
                  onPressed: () => _navigateTo(context, route),
                  icon: Icon(
                    route.icon,
                    size: 17,
                    color: isSelected
                        ? colorScheme.primary
                        : (isHighContrast ? Colors.white : colorScheme.onSurface),
                  ),
                  label: Text(
                    route.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : (isHighContrast ? Colors.white : colorScheme.onSurface),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: isSelected
                        ? (isHighContrast
                            ? colorScheme.primary.withValues(alpha: 0.15)
                            : colorScheme.primary.withValues(alpha: 0.08))
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: isSelected && isHighContrast
                          ? BorderSide(color: colorScheme.primary, width: 1.5)
                          : BorderSide.none,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
          ],

          // Any custom screen actions
          if (actions != null) ...actions!,

          // Theme Switcher dropdown visible in AppBar
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: ThemeSwitcher(style: ThemeSwitcherStyle.dropdown),
          ),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: isHighContrast ? Colors.black : colorScheme.surface,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: isHighContrast
                            ? Colors.black
                            : colorScheme.primary.withValues(alpha: 0.08),
                        border: Border(
                          bottom: BorderSide(
                            color: isHighContrast
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: isHighContrast ? 2.5 : 1.0,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.lock_rounded,
                                  color: colorScheme.onPrimary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Privacy Chatbot',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isHighContrast
                                        ? Colors.white
                                        : colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '100% Offline AI Assistant • Zero External Data Leaks',
                            style: TextStyle(
                              fontSize: 12,
                              color: isHighContrast
                                  ? const Color(0xFFDDDDDD)
                                  : colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: AppRoute.values.map((route) {
                          final isSelected = route == currentRoute;
                          return ListTile(
                            leading: Icon(
                              route.icon,
                              color: isSelected
                                  ? colorScheme.primary
                                  : (isHighContrast
                                      ? Colors.white
                                      : colorScheme.onSurface),
                            ),
                            title: Text(
                              route.title,
                              style: TextStyle(
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? colorScheme.primary
                                    : (isHighContrast
                                        ? Colors.white
                                        : colorScheme.onSurface),
                              ),
                            ),
                            selected: isSelected,
                            selectedTileColor: isHighContrast
                                ? colorScheme.primary.withValues(alpha: 0.15)
                                : colorScheme.primary.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: isSelected && isHighContrast
                                  ? BorderSide(color: colorScheme.primary, width: 2)
                                  : BorderSide.none,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _navigateTo(context, route);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme Preference',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isHighContrast
                                  ? Colors.white
                                  : colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const ThemeSwitcher(style: ThemeSwitcherStyle.segmented),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Common footer widget for the application
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isHighContrast = theme.scaffoldBackgroundColor == Colors.black &&
        colorScheme.primary == const Color(0xFFFFEA00);

    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 24,
                runSpacing: 16,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.shield_rounded,
                          size: 18,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Privacy-Preserving Chatbot',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isHighContrast ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 16,
                    children: [
                      _buildFooterBadge(
                        context,
                        icon: Icons.wifi_off_rounded,
                        text: '100% Offline AI',
                        isHighContrast: isHighContrast,
                      ),
                      _buildFooterBadge(
                        context,
                        icon: Icons.fingerprint_rounded,
                        text: 'Zero Telemetry',
                        isHighContrast: isHighContrast,
                      ),
                      _buildFooterBadge(
                        context,
                        icon: Icons.accessibility_new_rounded,
                        text: 'WCAG AAA Contrast',
                        isHighContrast: isHighContrast,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(
                color: isHighContrast
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Local-first privacy architecture: all personal information and document contents stay securely on your device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isHighContrast
                      ? const Color(0xFFDDDDDD)
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterBadge(
    BuildContext context, {
    required IconData icon,
    required String text,
    required bool isHighContrast,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isHighContrast
            ? Colors.black
            : colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighContrast ? colorScheme.primary : colorScheme.outlineVariant,
          width: isHighContrast ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isHighContrast ? Colors.white : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
