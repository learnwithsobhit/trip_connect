import 'package:flutter/material.dart';

class TranslationService {
  static const Map<String, String> _supportedLanguages = {
    'en': 'English',
    'hi': 'हिंदी (Hindi)',
    'es': 'Español (Spanish)',
    'fr': 'Français (French)',
    'de': 'Deutsch (German)',
    'zh': '中文 (Chinese)',
    'ja': '日本語 (Japanese)',
    'ko': '한국어 (Korean)',
    'ar': 'العربية (Arabic)',
    'pt': 'Português (Portuguese)',
  };

  static const Map<String, String> _defaultLanguage = {'code': 'en', 'name': 'English'};

  // Mock translation data - in real app, this would use a translation API
  static const Map<String, Map<String, String>> _translations = {
    'hi': {
      'Welcome': 'स्वागत है',
      'Sign In': 'साइन इन करें',
      'Sign Up': 'साइन अप करें',
      'Email': 'ईमेल',
      'Password': 'पासवर्ड',
      'Create Trip': 'यात्रा बनाएं',
      'Join Trip': 'यात्रा में शामिल हों',
      'Chat': 'चैट',
      'Settings': 'सेटिंग्स',
      'Profile': 'प्रोफ़ाइल',
      'Weather': 'मौसम',
      'Checklist': 'चेकलिस्ट',
      'Transportation': 'परिवहन',
      'Health & Safety': 'स्वास्थ्य और सुरक्षा',
      'Documents': 'दस्तावेज़',
      'Media Gallery': 'मीडिया गैलरी',
    },
    'es': {
      'Welcome': 'Bienvenido',
      'Sign In': 'Iniciar Sesión',
      'Sign Up': 'Registrarse',
      'Email': 'Correo Electrónico',
      'Password': 'Contraseña',
      'Create Trip': 'Crear Viaje',
      'Join Trip': 'Unirse al Viaje',
      'Chat': 'Chat',
      'Settings': 'Configuración',
      'Profile': 'Perfil',
      'Weather': 'Clima',
      'Checklist': 'Lista de Verificación',
      'Transportation': 'Transporte',
      'Health & Safety': 'Salud y Seguridad',
      'Documents': 'Documentos',
      'Media Gallery': 'Galería de Medios',
    },
    'fr': {
      'Welcome': 'Bienvenue',
      'Sign In': 'Se Connecter',
      'Sign Up': "S'inscrire",
      'Email': 'E-mail',
      'Password': 'Mot de Passe',
      'Create Trip': 'Créer un Voyage',
      'Join Trip': 'Rejoindre le Voyage',
      'Chat': 'Chat',
      'Settings': 'Paramètres',
      'Profile': 'Profil',
      'Weather': 'Météo',
      'Checklist': 'Liste de Vérification',
      'Transportation': 'Transport',
      'Health & Safety': 'Santé et Sécurité',
      'Documents': 'Documents',
      'Media Gallery': 'Galerie Média',
    },
  };

  static List<Map<String, String>> get supportedLanguages {
    return _supportedLanguages.entries.map((entry) => {
      'code': entry.key,
      'name': entry.value,
    }).toList();
  }

  static Map<String, String> get defaultLanguage => _defaultLanguage;

  static String translate(String text, String targetLanguage) {
    if (targetLanguage == 'en') return text;
    
    final translations = _translations[targetLanguage];
    if (translations != null && translations.containsKey(text)) {
      return translations[text]!;
    }
    
    // Mock translation - in real app, this would call a translation API
    return _mockTranslate(text, targetLanguage);
  }

  static String _mockTranslate(String text, String targetLanguage) {
    // Simple mock translation for demo purposes
    switch (targetLanguage) {
      case 'hi':
        return '[हिंदी] $text';
      case 'es':
        return '[Español] $text';
      case 'fr':
        return '[Français] $text';
      case 'de':
        return '[Deutsch] $text';
      case 'zh':
        return '[中文] $text';
      case 'ja':
        return '[日本語] $text';
      case 'ko':
        return '[한국어] $text';
      case 'ar':
        return '[العربية] $text';
      case 'pt':
        return '[Português] $text';
      default:
        return text;
    }
  }

  static bool isLanguageSupported(String languageCode) {
    return _supportedLanguages.containsKey(languageCode);
  }

  static String getLanguageName(String languageCode) {
    return _supportedLanguages[languageCode] ?? 'Unknown';
  }
}
