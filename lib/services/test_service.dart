import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import '../config/mobile_config.dart';
import '../config/subject_constants.dart';
import '../models/app_models.dart';

class TestService {
  Future<AppTest?> loadDailyTest() async {
    if (Firebase.apps.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection(MobileFirebaseConfig.dailyTestsCollection)
            .doc(_todayKey())
            .get();
        if (doc.exists) {
          final test = _toTest({...?doc.data(), 'id': doc.id}, id: doc.id, forceDaily: true);
          if (_isValidTest(test)) return test;
        }

        final fallback = await FirebaseFirestore.instance
            .collection(MobileFirebaseConfig.dailyTestsCollection)
            .where('active', isEqualTo: true)
            .orderBy('date', descending: true)
            .limit(1)
            .get();
        if (fallback.docs.isNotEmpty) {
          final doc = fallback.docs.first;
          final test = _toTest({...doc.data(), 'id': doc.id}, id: doc.id, forceDaily: true);
          if (_isValidTest(test)) return test;
        }
      } catch (_) {}
    }

    // REST Fallback for Daily
    try {
      final dailyDoc = await _fetchSingleDocument('${MobileFirebaseConfig.dailyTestsCollection}/${_todayKey()}');
      if (dailyDoc != null) {
        final test = _toTest(dailyDoc, id: _todayKey(), forceDaily: true);
        if (_isValidTest(test)) return test;
      }
    } catch (_) {}

    return null;
  }

  Future<List<AppTest>> loadPublicTests() async {
    final tests = <AppTest>[];
    if (Firebase.apps.isNotEmpty) {
      try {
        final publicTests = await FirebaseFirestore.instance
            .collection(MobileFirebaseConfig.publicTestsCollection)
            .get();
        for (final doc in publicTests.docs) {
          _addIfValid(tests, _toTest({...doc.data(), 'id': doc.id}, id: doc.id, forcePublished: true));
        }
        if (tests.isNotEmpty) return tests;
      } catch (_) {}
    }

    // REST Fallback
    try {
      final publicDocs = await _fetchCollection(MobileFirebaseConfig.publicTestsCollection);
      for (final doc in publicDocs) {
        final id = (doc['id'] ?? '').toString();
        _addIfValid(tests, _toTest(doc, id: id, forcePublished: true));
      }
    } catch (_) {}

    return tests;
  }

  Future<List<AppTest>> loadTests() async {
    final results = await Future.wait([loadDailyTest(), loadPublicTests()]);
    final daily = results[0] as AppTest?;
    final public = results[1] as List<AppTest>;
    return [if (daily != null) daily, ...public];
  }

  Future<List<Map<String, dynamic>>> _fetchCollection(String collection) async {
    final response = await http.get(_documentsUri(collection));
    if (response.statusCode >= 400) {
      return const [];
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = decoded['documents'];
    if (documents is! List) {
      return const [];
    }

    return documents
        .whereType<Map>()
        .map((item) => _decodeDocument(item.cast<String, dynamic>()))
        .toList();
  }

  Future<Map<String, dynamic>?> _fetchSingleDocument(String path) async {
    final response = await http.get(_documentsUri(path));
    if (response.statusCode >= 400) {
      return null;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return _decodeDocument(decoded);
  }

  Uri _documentsUri(String path) {
    return Uri.parse(
      'https://firestore.googleapis.com/v1/projects/${MobileFirebaseConfig.projectId}/databases/(default)/documents/$path?key=${MobileFirebaseConfig.apiKey}',
    );
  }

  Map<String, dynamic> _decodeDocument(Map<String, dynamic> document) {
    final name = (document['name'] ?? '').toString();
    final fields =
        (document['fields'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    return {
      'id': name.split('/').isNotEmpty ? name.split('/').last : '',
      ..._decodeMap(fields),
    };
  }

  Map<String, dynamic> _decodeMap(Map<String, dynamic> fields) {
    final decoded = <String, dynamic>{};
    fields.forEach((key, value) {
      decoded[key] = _decodeValue(value as Map<String, dynamic>);
    });
    return decoded;
  }

  dynamic _decodeValue(Map<String, dynamic> value) {
    if (value.containsKey('stringValue')) {
      return value['stringValue'];
    }
    if (value.containsKey('integerValue')) {
      return int.tryParse(value['integerValue'].toString()) ?? 0;
    }
    if (value.containsKey('doubleValue')) {
      return (value['doubleValue'] as num).toDouble();
    }
    if (value.containsKey('booleanValue')) {
      return value['booleanValue'] == true;
    }
    if (value.containsKey('nullValue')) {
      return null;
    }
    if (value.containsKey('timestampValue')) {
      return value['timestampValue'];
    }
    if (value.containsKey('arrayValue')) {
      final values = ((value['arrayValue'] as Map<String, dynamic>)['values']
              as List<dynamic>? ??
          const []);
      return values
          .whereType<Map>()
          .map((item) => _decodeValue(item.cast<String, dynamic>()))
          .toList();
    }
    if (value.containsKey('mapValue')) {
      final fields = ((value['mapValue'] as Map<String, dynamic>)['fields']
              as Map<String, dynamic>? ??
          const <String, dynamic>{});
      return _decodeMap(fields);
    }
    return null;
  }

  AppTest _toTest(
    Map<String, dynamic> raw, {
    required String id,
    bool forcePublished = false,
    bool forceDaily = false,
  }) {
    return AppTest.fromJson(
      {
        'id': id,
        'title': raw['name'] ?? raw['title'] ?? 'Untitled Test',
        'subject': SubjectConstants.normalizeSubject((raw['subject'] ?? 'General').toString()),
        'chapter': raw['chapter_name'] ?? raw['chapter'] ?? '',
        'level': raw['level'] ?? 'Level 1',
        'timeLimitMin': raw['time_limit_min'] ?? raw['timeLimitMin'] ?? 0,
        'book': SubjectConstants.normalizeSubject((raw['book'] ?? '').toString()),
        'testType': raw['test_type'] ?? 'MCQ',
        'pyqYear': raw['pyq_year'] ?? '',
        'isPublished': forcePublished || raw['visibility'] == 'public',
        'isDaily': forceDaily || raw['active'] == true,
        'questions': raw['questions'] ?? const [],
      },
    );
  }

  void _addIfValid(List<AppTest> tests, AppTest test) {
    if (_isValidTest(test)) {
      tests.add(test);
    }
  }

  bool _isValidTest(AppTest test) {
    if (test.id.trim().isEmpty || test.title.trim().isEmpty) {
      return false;
    }
    if (test.questions.isEmpty) {
      return false;
    }

    for (final question in test.questions) {
      if (question.question.trim().isEmpty) {
        return false;
      }
      if (question.isObjective) {
        if (question.options.length < 2) {
          return false;
        }
      }
    }

    return true;
  }

  String _todayKey() {
    final today = DateTime.now();
    return '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
  }
}
