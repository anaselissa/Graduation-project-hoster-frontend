import '../services/api_service.dart';

class OpenAIService {
  static Future<String> getChatResponse(String message) async {
    try {
      final reply = await ApiService().sendChatMessage(message);
      return reply;
    } catch (e) {
      return 'عذراً، واجهت مشكلة في الاتصال بالخادم: $e';
    }
  }
}
