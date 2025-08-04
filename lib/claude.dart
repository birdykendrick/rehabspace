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
      // converts the request body into a JSON string that only API exepects RMB THIS
      "model": "mistralai/mistral-7b-instruct",
      "max_tokens": 200,
      "messages": [
        {
          "role": "system",
          "content":
              "You are a helpful assistant that only answers questions related to rehabilitation, physiotherapy, recovery exercises, injury healing, nutrition for recovery, and general wellness advice. Please keep your responses clear, simple, and concise. Limit answers to a few sentences. If the user asks something unrelated to rehabilitation, respond with: 'I only assist with rehab-related questions.'",
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
