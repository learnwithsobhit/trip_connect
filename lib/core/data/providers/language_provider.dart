import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/translation_service.dart';

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en');

  void setLanguage(String languageCode) {
    if (TranslationService.isLanguageSupported(languageCode)) {
      state = languageCode;
    }
  }

  String get currentLanguage => state;
  
  String get currentLanguageName => TranslationService.getLanguageName(state);
  
  List<Map<String, String>> get supportedLanguages => TranslationService.supportedLanguages;
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

final languageNotifierProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

final currentLanguageNameProvider = Provider<String>((ref) {
  final languageCode = ref.watch(languageProvider);
  return TranslationService.getLanguageName(languageCode);
});

final supportedLanguagesProvider = Provider<List<Map<String, String>>>((ref) {
  return TranslationService.supportedLanguages;
});
