import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String groqApiKeyDefine =
      String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const String backendBaseUrlDefine =
      String.fromEnvironment('BACKEND_BASE_URL', defaultValue: '');

  static String groqApiKey() {
    if (groqApiKeyDefine.trim().isNotEmpty) {
      return groqApiKeyDefine.trim();
    }
    return (dotenv.env['GROQ_API_KEY'] ?? '').trim();
  }

  static String backendBaseUrl() {
    if (backendBaseUrlDefine.trim().isNotEmpty) {
      return backendBaseUrlDefine.trim();
    }
    return (dotenv.env['BACKEND_BASE_URL'] ?? 'http://127.0.0.1:8000').trim();
  }
}

