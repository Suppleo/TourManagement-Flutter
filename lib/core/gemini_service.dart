import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyCNha13piIIYxKJdJAO_1ZIM9CepnCKWTg';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey';



  static Future<String> sendMessage(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        // ✅ Trả về thông tin hoặc fallback an toàn
        return text is String && text.trim().isNotEmpty
            ? text.trim()
            : '⚠️ Gemini không có phản hồi.';
      } else {
        final error = jsonDecode(response.body);
        final msg = error['error']?['message'] ?? 'Không xác định';
        return '❌ Lỗi Gemini ${response.statusCode}: $msg';
      }
    } catch (e) {
      return '❌ Lỗi khi gọi Gemini: $e';
    }
  }
}
