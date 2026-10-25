import 'package:flutter/material.dart';

/// Reusable feature card used on the Home screen and other landing sections
class FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? badgeText;
  final Color? accentColor;
  final VoidCallback? onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.badgeText,
    this.accentColor,
    this.onTap,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isHighContrast = theme.scaffoldBackgroundColor == Colors.black &&
        colorScheme.primary == const Color(0xFFFFEA00);

    final cardBorderColor = isHighContrast
        ? (_isHovered ? colorScheme.secondary : colorScheme.primary)
        : (_isHovered ? colorScheme.primary : colorScheme.outlineVariant);

    final iconColor = isHighContrast
        ? colorScheme.primary
        : (widget.accentColor ?? colorScheme.primary);

    final iconBgColor = isHighContrast
        ? Colors.black
        : (widget.accentColor ?? colorScheme.primary).withValues(alpha: 0.12);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: cardBorderColor,
              width: isHighContrast ? 2.5 : (_isHovered ? 1.5 : 1.0),
            ),
          ),
          elevation: isHighContrast ? 0 : (_isHovered ? 8 : 1),
          shadowColor: colorScheme.primary.withValues(alpha: 0.1),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: isHighContrast
                              ? Border.all(color: colorScheme.primary, width: 2.0)
                              : null,
                        ),
                        child: Icon(
                          widget.icon,
                          size: 26,
                          color: iconColor,
                        ),
                      ),
                      if (widget.badgeText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
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
                          child: Text(
                            widget.badgeText!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isHighContrast
                                  ? colorScheme.secondary
                                  : colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                      color: isHighContrast ? Colors.white : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: isHighContrast
                          ? const Color(0xFFDDDDDD)
                          : colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
