import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_themes.dart';
import '../theme/theme_controller.dart';

enum ThemeSwitcherStyle {
  dropdown,
  segmented,
  cards,
}

/// A reusable Theme Switcher widget supporting dropdown, segmented, and card selection styles
class ThemeSwitcher extends StatelessWidget {
  final ThemeSwitcherStyle style;
  final bool showLabel;

  const ThemeSwitcher({
    super.key,
    this.style = ThemeSwitcherStyle.dropdown,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final currentTheme = themeController.currentTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isHighContrast = themeController.isHighContrast;

    switch (style) {
      case ThemeSwitcherStyle.dropdown:
        return _buildDropdown(context, themeController, currentTheme, colorScheme, isHighContrast);
      case ThemeSwitcherStyle.segmented:
        return _buildSegmented(context, themeController, currentTheme, colorScheme, isHighContrast);
      case ThemeSwitcherStyle.cards:
        return _buildCards(context, themeController, currentTheme, colorScheme, isHighContrast);
    }
  }

  Widget _buildDropdown(
    BuildContext context,
    ThemeController themeController,
    AppTheme currentTheme,
    ColorScheme colorScheme,
    bool isHighContrast,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.black : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighContrast ? colorScheme.primary : colorScheme.outlineVariant,
          width: isHighContrast ? 2.0 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppTheme>(
          value: currentTheme,
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: colorScheme.primary,
          ),
          dropdownColor: isHighContrast ? Colors.black : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          items: AppTheme.values.map((theme) {
            final isSelected = theme == currentTheme;
            return DropdownMenuItem<AppTheme>(
              value: theme,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    theme.icon,
                    size: 18,
                    color: isSelected
                        ? colorScheme.primary
                        : (isHighContrast ? Colors.white : colorScheme.onSurface),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    theme.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : (isHighContrast ? Colors.white : colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (newTheme) {
            if (newTheme != null) {
              themeController.setTheme(newTheme);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSegmented(
    BuildContext context,
    ThemeController themeController,
    AppTheme currentTheme,
    ColorScheme colorScheme,
    bool isHighContrast,
  ) {
    return SegmentedButton<AppTheme>(
      segments: AppTheme.values.map((theme) {
        return ButtonSegment<AppTheme>(
          value: theme,
          icon: Icon(theme.icon, size: 18),
          label: Text(theme.displayName),
        );
      }).toList(),
      selected: {currentTheme},
      onSelectionChanged: (Set<AppTheme> newSelection) {
        if (newSelection.isNotEmpty) {
          themeController.setTheme(newSelection.first);
        }
      },
      style: ButtonStyle(
        side: WidgetStateProperty.resolveWith((states) {
          return BorderSide(
            color: isHighContrast ? colorScheme.primary : colorScheme.outline,
            width: isHighContrast ? 2.5 : 1.0,
          );
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isHighContrast ? colorScheme.primary : colorScheme.primaryContainer;
          }
          return isHighContrast ? Colors.black : Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isHighContrast ? Colors.black : colorScheme.onPrimaryContainer;
          }
          return isHighContrast ? Colors.white : colorScheme.onSurface;
        }),
      ),
    );
  }

  Widget _buildCards(
    BuildContext context,
    ThemeController themeController,
    AppTheme currentTheme,
    ColorScheme colorScheme,
    bool isHighContrast,
  ) {
    final cards = AppTheme.values.map((theme) {
      final isSelected = theme == currentTheme;
      return InkWell(
        onTap: () => themeController.setTheme(theme),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? (isHighContrast
                    ? Colors.black
                    : colorScheme.primary.withValues(alpha: 0.08))
                : (isHighContrast ? Colors.black : colorScheme.surface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : (isHighContrast
                      ? const Color(0xFF444444)
                      : colorScheme.outlineVariant),
              width: isSelected
                  ? (isHighContrast ? 3.0 : 2.0)
                  : (isHighContrast ? 2.0 : 1.0),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : (isHighContrast
                          ? Colors.grey[900]
                          : colorScheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(12),
                  border: isHighContrast
                      ? Border.all(color: colorScheme.primary, width: 1.5)
                      : null,
                ),
                child: Icon(
                  theme.icon,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : (isHighContrast ? Colors.white : colorScheme.onSurface),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          theme.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isHighContrast ? Colors.white : colorScheme.onSurface,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      theme.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isHighContrast
                            ? const Color(0xFFDDDDDD)
                            : colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : (isHighContrast ? Colors.white : colorScheme.outline),
                    width: isHighContrast ? 2.5 : 2.0,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: colorScheme.onPrimary,
                      )
                    : null,
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Column(
      children: cards
          .map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: card,
            ),
          )
          .toList(),
    );
  }
}
