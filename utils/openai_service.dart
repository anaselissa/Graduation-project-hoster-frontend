import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
static const String _baseUrl = 'http://192.168.1.112:3000/api/chat';

  static Future<String> getChatResponse(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['reply'];
      } else {
        return 'عذراً، واجهت مشكلة في الاتصال بالسيرفر.';
      }
    } catch (e) {
      return 'خطأ في الاتصال: $e';
    }
  }
}
