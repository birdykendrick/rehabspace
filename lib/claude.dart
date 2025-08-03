import 'dart:convert';
import 'package:http/http.dart' as http;

class ClaudeService {
  final String _apiKey =
      "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";

  Future<String> getRehabResponse(String userInput) async {
    final uri = Uri.parse("https://openrouter.ai/api/v1/chat/completions");

    final headers = {
      "Authorization": "Bearer $_apiKey",
      "Content-Type": "application/json",
      "HTTP-Referer": "https://rehabspace.com",
      "X-Title": "RehabBot",
    };

    final body = jsonEncode({
      "model": "mistralai/mistral-7b-instruct",
      "max_tokens": 300,
      "messages": [
        {
          "role": "system",
          "content":
              "You are a helpful assistant that ONLY answers questions related to rehabilitation, physiotherapy, meals for injury, recovery exercises, injury healing, and wellness advice. Please be as concise as possible. If a user asks anything unrelated to rehab, kindly respond with: 'I only assist with rehab-related questions.'",
        },
        {"role": "user", "content": userInput},
      ],
    });

    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].toString().trim();
    } else {
      return "Error: ${response.statusCode}\n${response.body}";
    }
  }
}
