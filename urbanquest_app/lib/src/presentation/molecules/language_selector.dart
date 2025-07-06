import 'package:flutter/material.dart';
import '../../core/services/language_service.dart';
import '../../data/models/language_model.dart';

class LanguageSelector extends StatefulWidget {
  final Function(Language)? onLanguageChanged;
  final bool showFlags;
  final bool showAsDialog;

  const LanguageSelector({
    super.key,
    this.onLanguageChanged,
    this.showFlags = true,
    this.showAsDialog = false,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  final LanguageService _languageService = LanguageService();

  @override
  Widget build(BuildContext context) {
    final availableLanguages = _languageService.sortedLanguages;
    final currentLanguage = _languageService.currentLanguage;

    if (availableLanguages.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.showAsDialog) {
      return IconButton(
        icon: const Icon(Icons.language),
        onPressed: () => _showLanguageDialog(context),
      );
    }

    return DropdownButton<String>(
      value: currentLanguage?.code ?? 'en',
      underline: Container(),
      items: availableLanguages.map((language) {
        return DropdownMenuItem<String>(
          value: language.code,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showFlags && language.flagEmoji != null) ...[
                Text(
                  language.flagEmoji!,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
              ],
              Text(language.nativeName),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? languageCode) {
        if (languageCode != null && languageCode.isNotEmpty) {
          _changeLanguage(languageCode);
        }
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final availableLanguages = _languageService.sortedLanguages;
    final currentLanguage = _languageService.currentLanguage;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: availableLanguages.map((language) {
                final isSelected = currentLanguage?.code == language.code;
                
                return ListTile(
                  leading: language.flagEmoji != null 
                    ? Text(
                        language.flagEmoji!,
                        style: const TextStyle(fontSize: 24),
                      )
                    : const Icon(Icons.language),
                  title: Text(language.name),
                  subtitle: Text(language.nativeName),
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                  selected: isSelected,
                  onTap: () {
                    _changeLanguage(language.code);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeLanguage(String languageCode) async {
    final success = await _languageService.changeLanguage(languageCode);
    
    if (success && mounted) {
      final newLanguage = _languageService.currentLanguage;
      if (newLanguage != null) {
        // Notify parent widget
        widget.onLanguageChanged?.call(newLanguage);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed to ${newLanguage.nativeName}'),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Trigger rebuild
        setState(() {});
      }
    } else if (mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to change language'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class LanguageSelectorTile extends StatelessWidget {
  final Function(Language)? onLanguageChanged;

  const LanguageSelectorTile({
    super.key,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService();
    final currentLanguage = languageService.currentLanguage;

    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('Language'),
      subtitle: Text(
        currentLanguage != null 
          ? '${currentLanguage.flagEmoji ?? '🌍'} ${currentLanguage.nativeName}'
          : 'Select language',
      ),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _showLanguageBottomSheet(context),
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    final languageService = LanguageService();
    final availableLanguages = languageService.sortedLanguages;
    final currentLanguage = languageService.currentLanguage;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableLanguages.length,
                  itemBuilder: (context, index) {
                    final language = availableLanguages[index];
                    final isSelected = currentLanguage?.code == language.code;
                    
                    return ListTile(
                      leading: language.flagEmoji != null 
                        ? Text(
                            language.flagEmoji!,
                            style: const TextStyle(fontSize: 24),
                          )
                        : const Icon(Icons.language),
                      title: Text(language.name),
                      subtitle: Text(language.nativeName),
                      trailing: isSelected 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.circle_outlined),
                      selected: isSelected,
                      onTap: () async {
                        final success = await languageService.changeLanguage(language.code);
                        if (success && context.mounted) {
                          onLanguageChanged?.call(language);
                          Navigator.of(context).pop();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Language changed to ${language.nativeName}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
} 