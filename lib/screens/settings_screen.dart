import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/personal_data.dart';
import '../services/document_service.dart';
import '../services/local_data_service.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_nav_scaffold.dart';
import '../widgets/theme_switcher.dart';

/// Settings page for theme switching, privacy controls, and local profile inspection
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalDataService _localDataService = LocalDataService();
  final DocumentService _documentService = DocumentService();
  PersonalData? _personalData;
  bool _isLoading = true;
  int _documentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  Future<void> _loadSettingsData() async {
    setState(() => _isLoading = true);
    final data = await _localDataService.getPersonalData();
    await _documentService.loadDocuments();
    final docs = _documentService.getDocuments();

    if (mounted) {
      setState(() {
        _personalData = data;
        _documentCount = docs.length;
        _isLoading = false;
      });
    }
  }

  Future<void> _resetSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isHighContrast =
            Provider.of<ThemeController>(context, listen: false).isHighContrast;

        return AlertDialog(
          title: Text(
            'Reset Sample Data',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighContrast ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Reset personal information to default demo records? Your custom edits will be replaced with fresh sample data.',
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
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _localDataService.resetToSampleData();
      await _loadSettingsData();
      if (mounted) {
        _showSnackBar('Personal data reset to default sample values.');
      }
    }
  }

  Future<void> _clearAllApplicationData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isHighContrast =
            Provider.of<ThemeController>(context, listen: false).isHighContrast;

        return AlertDialog(
          title: Text(
            'Clear All Application Data',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighContrast ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          content: Text(
            'This will delete all uploaded documents and indices. (Theme preferences will remain).',
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
              child: const Text('Delete Everything'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _documentService.clearAllDocuments();
      await _loadSettingsData();
      if (mounted) {
        _showSnackBar('All document storage cleared.');
      }
    }
  }

  void _showEditProfileDialog() {
    if (_personalData == null) return;

    final nameController = TextEditingController(text: _personalData!.name);
    final emailController = TextEditingController(text: _personalData!.email);
    final phoneController = TextEditingController(text: _personalData!.phone);
    final addressController = TextEditingController(text: _personalData!.address);
    final dobController = TextEditingController(text: _personalData!.dateOfBirth);

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isHighContrast =
            Provider.of<ThemeController>(context, listen: false).isHighContrast;

        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Local Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isHighContrast ? colorScheme.primary : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This information is stored exclusively in your browser\'s local storage and used to answer your chat questions.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isHighContrast ? const Color(0xFFDDDDDD) : colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email Address'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dobController,
                      decoration: const InputDecoration(labelText: 'Date of Birth'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final updated = PersonalData(
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                              phone: phoneController.text.trim(),
                              address: addressController.text.trim(),
                              dateOfBirth: dobController.text.trim(),
                              occupation: _personalData!.occupation,
                              preferences: _personalData!.preferences,
                              interests: _personalData!.interests,
                            );
                            await _localDataService.savePersonalData(updated);
                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadSettingsData();
                              _showSnackBar('Profile updated in local storage.');
                            }
                          },
                          child: const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
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
        backgroundColor: isHighContrast ? colorScheme.primary : colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeController = Provider.of<ThemeController>(context);
    final isHighContrast = themeController.isHighContrast;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    return AppNavScaffold(
      currentRoute: AppRoute.settings,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 20,
                vertical: isDesktop ? 40 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Application Settings',
                        style: TextStyle(
                          fontSize: isDesktop ? 32 : 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isHighContrast ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configure visual appearance, theme mode, and client-side privacy controls.',
                        style: TextStyle(
                          fontSize: 15,
                          color: isHighContrast
                              ? const Color(0xFFDDDDDD)
                              : colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Section 1: Theme Switcher
                      _buildSectionTitle(
                        context,
                        title: 'Theme & Appearance',
                        icon: Icons.palette_outlined,
                        isHighContrast: isHighContrast,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Display Theme',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isHighContrast ? Colors.white : colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your preference is saved locally and applies immediately across all pages without restarting.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isHighContrast
                                      ? const Color(0xFFDDDDDD)
                                      : colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const ThemeSwitcher(style: ThemeSwitcherStyle.cards),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Section 2: Local Personal Information
                      _buildSectionTitle(
                        context,
                        title: 'Local Profile Information',
                        icon: Icons.person_outline_rounded,
                        isHighContrast: isHighContrast,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'On-Device Profile Data',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isHighContrast
                                                ? Colors.white
                                                : colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Used by the local NLP model when answering questions like "What is my email?"',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isHighContrast
                                                ? const Color(0xFFDDDDDD)
                                                : colorScheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: _showEditProfileDialog,
                                    icon: const Icon(Icons.edit_rounded, size: 16),
                                    label: const Text('Edit Profile'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (_personalData != null) ...[
                                _buildDataRow('Full Name', _personalData!.name, isHighContrast),
                                _buildDataRow('Email Address', _personalData!.email, isHighContrast),
                                _buildDataRow('Phone Number', _personalData!.phone, isHighContrast),
                                _buildDataRow('Address', _personalData!.address, isHighContrast),
                                _buildDataRow('Date of Birth', _personalData!.dateOfBirth, isHighContrast),
                              ],
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _resetSampleData,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Reset Demo Sample Data'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Section 3: Privacy & Storage Controls
                      _buildSectionTitle(
                        context,
                        title: 'Storage & Privacy Guarantees',
                        icon: Icons.shield_outlined,
                        isHighContrast: isHighContrast,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPrivacyGuaranteeItem(
                                icon: Icons.wifi_off_rounded,
                                title: 'Zero Network Outflow',
                                description: 'Chat queries and uploaded files never transmit over HTTP or WebSockets.',
                                isHighContrast: isHighContrast,
                              ),
                              const SizedBox(height: 14),
                              _buildPrivacyGuaranteeItem(
                                icon: Icons.storage_rounded,
                                title: 'Local Browser Sandboxing',
                                description: 'Currently storing $_documentCount loaded document(s) in browser memory/storage.',
                                isHighContrast: isHighContrast,
                              ),
                              const SizedBox(height: 14),
                              _buildPrivacyGuaranteeItem(
                                icon: Icons.code_rounded,
                                title: 'Auditable & Open-Source',
                                description: 'Pure Dart TF-IDF vectorizer and token matcher with full code transparency.',
                                isHighContrast: isHighContrast,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _clearAllApplicationData,
                                icon: const Icon(Icons.delete_forever_rounded),
                                label: const Text('Clear All Loaded Documents'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.error,
                                  foregroundColor: colorScheme.onError,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Section 4: System Information
                      _buildSectionTitle(
                        context,
                        title: 'Application Information',
                        icon: Icons.info_outline_rounded,
                        isHighContrast: isHighContrast,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildInfoRow('Application', 'Privacy-Preserving Chatbot Web', isHighContrast),
                              _buildInfoRow('Version', '1.0.0+1', isHighContrast),
                              _buildInfoRow('Engine', 'Flutter 3.44+ (CanvasKit / Web)', isHighContrast),
                              _buildInfoRow('NLP Architecture', 'Pure Dart On-Device TF-IDF Vectorizer', isHighContrast),
                              _buildInfoRow('Accessibility', 'WCAG AAA High-Contrast Standard Compliant', isHighContrast),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isHighContrast,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isHighContrast ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value, bool isHighContrast) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: isHighContrast ? colorScheme.primary : colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isHighContrast ? Colors.white : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyGuaranteeItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isHighContrast,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHighContrast
                ? Colors.black
                : colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: isHighContrast
                ? Border.all(color: colorScheme.secondary, width: 1.5)
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isHighContrast ? colorScheme.secondary : colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: isHighContrast ? Colors.white : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
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
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isHighContrast) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: isHighContrast ? const Color(0xFFDDDDDD) : colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: isHighContrast ? Colors.white : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
