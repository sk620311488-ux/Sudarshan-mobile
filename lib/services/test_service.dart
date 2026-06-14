import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import '../config/mobile_config.dart';
import '../models/app_models.dart';

class TestService {
  Future<List<AppTest>> loadTests() async {
    if (Firebase.apps.isNotEmpty) {
      final firestoreTests = await _loadTestsFromFirestore();
      if (firestoreTests.isNotEmpty) {
        return firestoreTests;
      }
    }

    return _loadTestsWithRest();
  }

  Future<List<AppTest>> _loadTestsFromFirestore() async {
    final tests = <AppTest>[];

    final dailyDoc = await FirebaseFirestore.instance
        .collection(MobileFirebaseConfig.dailyTestsCollection)
        .doc(_todayKey())
        .get();

    if (dailyDoc.exists) {
      _addIfValid(
        tests,
        _toTest(
          {...?dailyDoc.data(), 'id': dailyDoc.id},
          id: dailyDoc.id,
          forceDaily: true,
        ),
      );
    } else {
      final fallbackDaily = await FirebaseFirestore.instance
          .collection(MobileFirebaseConfig.dailyTestsCollection)
          .where('active', isEqualTo: true)
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      if (fallbackDaily.docs.isNotEmpty) {
        final doc = fallbackDaily.docs.first;
        _addIfValid(
          tests,
          _toTest(
            {...doc.data(), 'id': doc.id},
            id: doc.id,
            forceDaily: true,
          ),
        );
      }
    }

    final publicTests = await FirebaseFirestore.instance
        .collection(MobileFirebaseConfig.publicTestsCollection)
        .get();
    for (final doc in publicTests.docs) {
      if (tests.any((test) => test.id == doc.id)) {
        continue;
      }
      _addIfValid(
        tests,
        _toTest(
          {...doc.data(), 'id': doc.id},
          id: doc.id,
          forcePublished: true,
        ),
      );
    }

    return tests;
  }

  Future<List<AppTest>> _loadTestsWithRest() async {
    final tests = <AppTest>[];

    final dailyDoc = await _fetchSingleDocument(
      '${MobileFirebaseConfig.dailyTestsCollection}/${_todayKey()}',
    );
    if (dailyDoc != null) {
      _addIfValid(tests, _toTest(dailyDoc, id: _todayKey(), forceDaily: true));
    } else {
      final dailyDocs =
          await _fetchCollection(MobileFirebaseConfig.dailyTestsCollection);
      dailyDocs.sort(
        (a, b) => (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()),
      );

      for (final doc in dailyDocs) {
        if (doc['active'] != true) {
          continue;
        }
        final id = (doc['id'] ?? '').toString();
        if (id.isEmpty) {
          continue;
        }
        _addIfValid(tests, _toTest(doc, id: id, forceDaily: true));
        break;
      }
    }

    final publicDocs =
        await _fetchCollection(MobileFirebaseConfig.publicTestsCollection);
    for (final doc in publicDocs) {
      final id = (doc['id'] ?? '').toString();
      if (id.isEmpty || tests.any((test) => test.id == id)) {
        continue;
      }
      _addIfValid(tests, _toTest(doc, id: id, forcePublished: true));
    }

    return tests;
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
        'subject': raw['subject'] ?? 'General',
        'chapter': raw['chapter_name'] ?? raw['chapter'] ?? '',
        'level': raw['level'] ?? 'Level 1',
        'timeLimitMin': raw['time_limit_min'] ?? raw['timeLimitMin'] ?? 0,
        'book': raw['book'] ?? '',
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
      if (question.question.trim().isEmpty || question.topic.trim().isEmpty) {
        return false;
      }
      if (question.isObjective) {
        if (question.options.length < 2 || question.answerIndex < 0) {
          return false;
        }
      } else if (question.answerText.trim().isEmpty) {
        return false;
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
