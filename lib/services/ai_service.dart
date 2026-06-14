import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/mobile_config.dart';
import '../models/app_models.dart';

class AiService {
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String _apiKey = MobileFirebaseConfig.groqApiKey;
  final String _visionModel = 'llama-3.2-11b-vision-preview';

  Future<Map<String, dynamic>> evaluateSubjectiveAnswer({
    required String question,
    required String modelAnswer,
    required String studentAnswer,
    String? imageBase64,
  }) async {
    final prompt = '''
Evaluate the following student's answer against the model answer for a subjective question.
Question: "$question"
Model Answer: "$modelAnswer"
${imageBase64 != null ? 'The student has uploaded a photo of their handwritten answer.' : 'Student Answer: "$studentAnswer"'}

Provide:
1. A score from 0 to 100 based on accuracy, completeness, and clarity.
2. Short, constructive feedback in Hindi or English (depending on the question's language).
3. If an image is provided, transcribe the text briefly if possible and evaluate it.

Format your response as a valid JSON object:
{"score": 85, "feedback": "Your explanation is good but you missed the keyword...", "transcription": "..." }
''';

    try {
      final response = await _postToGroq(prompt, imageBase64: imageBase64);
      final data = jsonDecode(response);
      return {
        'score': data['score'] ?? 0,
        'feedback': data['feedback'] ?? 'No feedback available.',
        'transcription': data['transcription'] ?? '',
      };
    } catch (e) {
      return {'score': 0, 'feedback': 'AI evaluation failed: $e'};
    }
  }

  Future<String> analyzePerformance({
    required List<AppAttempt> attempts,
    required Map<String, double> mastery,
  }) async {
    final prompt = '''
Analyze the following student performance data and provide a detailed analysis in Hindi and English mix.
Attempts: ${attempts.length}
Recent Scores: ${attempts.take(5).map((e) => '${e.testTitle}: ${e.percent}%').join(', ')}
Subject Mastery: $mastery

Provide:
1. Overall progress summary.
2. Strengths and weaknesses.
3. Actionable tips to improve.
Keep it under 200 words.
''';

    try {
      return await _postToGroq(prompt);
    } catch (e) {
      return 'Could not generate analysis: $e';
    }
  }

  Future<String> explainQuestion({
    required String question,
    required String answer,
    String explanation = '',
  }) async {
    final prompt = '''
Explain this question and its correct answer in simple, easy-to-understand terms for a student in Hindi/English mix.
Question: "$question"
Correct Answer: "$answer"
${explanation.isNotEmpty ? 'Reference Explanation: "$explanation"' : ''}

Make the explanation helpful and encouraging. Keep it under 100 words.
''';

    try {
      return await _postToGroq(prompt);
    } catch (e) {
      return 'Could not generate explanation: $e';
    }
  }

  Future<String> _postToGroq(String prompt, {String? imageBase64}) async {
    final bool isVision = imageBase64 != null;
    final model = isVision ? _visionModel : MobileFirebaseConfig.groqModel;

    final List<dynamic> userMessageContent = [];
    userMessageContent.add({'type': 'text', 'text': prompt});

    if (isVision) {
      userMessageContent.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'}
      });
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': 'You are Sudarshan AI, a helpful and precise educational assistant. Always respond in a clear, encouraging manner.'},
          {'role': 'user', 'content': isVision ? userMessageContent : prompt},
        ],
        'temperature': 0.7,
        'response_format': prompt.contains('JSON') ? {'type': 'json_object'} : null,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].toString();
    } else {
      throw Exception('Groq API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
