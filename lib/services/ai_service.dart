import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/mobile_config.dart';
import '../models/app_models.dart';

class AiService {
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String _apiKey = MobileFirebaseConfig.groqApiKey;

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
Student Answer: "$studentAnswer"
${imageBase64 != null ? 'The student also attached a handwritten photo. Use it only as context; grade from the answer text.' : ''}

Strict Instructions:
1. Provide response strictly in Hindi (Devanagari script).
2. Evaluate based on key keywords presence.
3. Check for grammatical errors and sentence structure in Hindi.
4. Do not hallucinate. If the student's answer is completely irrelevant, give 0 score.

Provide:
1. A score from 0 to 100 based on accuracy, completeness, and clarity.
2. Constructive feedback in Hindi about keywords and grammar.
3. A detailed explanation of the correct answer and why the student got their score.
4. If an image is provided, transcribe the text briefly if possible and evaluate it.

Format your response as a valid JSON object:
{"score": 85, "feedback": "Hindi feedback here...", "explanation": "Detailed Hindi explanation...", "transcription": "..." }
''';

    try {
      final response = await _postToGroq(prompt, forceJson: true);
      final data = jsonDecode(response);
      return {
        'score': data['score'] ?? 0,
        'feedback': data['feedback'] ?? 'कोई प्रतिक्रिया उपलब्ध नहीं है।',
        'explanation': data['explanation'] ?? '',
        'transcription': data['transcription'] ?? '',
      };
    } catch (e) {
      return {'score': 0, 'feedback': 'AI मूल्यांकन विफल रहा: $e'};
    }
  }

  Future<String> analyzePerformance({
    required List<AppAttempt> attempts,
    required Map<String, double> mastery,
  }) async {
    final prompt = '''
Analyze the following student performance data.
Attempts: ${attempts.length}
Recent Scores: ${attempts.take(5).map((e) => '${e.testTitle}: ${e.percent}%').join(', ')}
Subject Mastery: $mastery

Strict Instructions:
1. Respond strictly in Hindi.
2. Provide:
   - Overall progress summary.
   - Strengths and weaknesses (based on subjects/scores).
   - Actionable tips to improve.
3. Keep it under 200 words. Do not hallucinate data.
''';

    try {
      return await _postToGroq(prompt);
    } catch (e) {
      return 'विश्लेषण उत्पन्न नहीं किया जा सका: $e';
    }
  }

  Future<String> explainQuestion({
    required String question,
    required String answer,
    String explanation = '',
  }) async {
    final prompt = '''
Explain this question and its correct answer in simple terms for a student.
Question: "$question"
Correct Answer: "$answer"
${explanation.isNotEmpty ? 'Reference Explanation: "$explanation"' : ''}

Strict Instructions:
1. Respond strictly in Hindi.
2. Make the explanation helpful and encouraging.
3. Keep it under 100 words.
''';

    try {
      return await _postToGroq(prompt);
    } catch (e) {
      return 'स्पष्टीकरण उत्पन्न नहीं किया जा सका: $e';
    }
  }

  Future<String> explainDeep({
    required String subject,
    required String chapter,
    required String topic,
    String? context,
  }) async {
    final prompt = '''
Provide a deep, expert-level explanation for a student.
Subject: "$subject"
Chapter: "$chapter"
Topic: "$topic"
${context != null ? 'Additional Context: "$context"' : ''}

Strict Instructions:
1. Respond strictly in Hindi.
2. Explain the core concepts, common pitfalls, and why this topic is important.
3. Use simple analogies where possible.
4. Avoid hallucination. If you don't have enough info on the topic, provide a general educational guidance for that subject area.
5. Keep it around 250 words.
''';

    try {
      return await _postToGroq(prompt);
    } catch (e) {
      return 'गहन स्पष्टीकरण उत्पन्न नहीं किया जा सका: $e';
    }
  }

  Future<String> _postToGroq(String prompt, {bool forceJson = false}) async {
    final model = MobileFirebaseConfig.groqModel;

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': 'You are Sovereign AI, a helpful, precise, and secure educational assistant. You strictly follow instructions and respond only in Hindi.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'response_format': forceJson || prompt.contains('JSON') ? {'type': 'json_object'} : null,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].toString();
    } else {
      throw Exception('Groq API Error: ${response.statusCode}');
    }
  }
}
