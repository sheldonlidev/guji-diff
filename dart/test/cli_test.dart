// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:guji_diff/guji_diff.dart';

void main() {
  group('CLI Tool Logic Tests', () {
    const doc1Path = 'test/temp_doc1.json';
    const doc2Path = 'test/temp_doc2.json';

    setUp(() {
      File(doc1Path).createSync(recursive: true);
      File(doc1Path).writeAsStringSync(
        jsonEncode({
          "chapters": [
            {
              "title": "Chapter 1",
              "paragraphs": [
                {"id": "p1", "content": "Hello World"},
              ],
            },
          ],
        }),
      );
      File(doc2Path).createSync(recursive: true);
      File(doc2Path).writeAsStringSync(
        jsonEncode({
          "chapters": [
            {
              "title": "Chapter 1 Modified",
              "paragraphs": [
                {"id": "p1", "content": "Hello World Updated"},
              ],
            },
          ],
        }),
      );
    });

    tearDown(() {
      if (File(doc1Path).existsSync()) File(doc1Path).deleteSync();
      if (File(doc2Path).existsSync()) File(doc2Path).deleteSync();
    });

    test('Verbatim comparison logic', () {
      final text1 = '大学之道';
      final text2 = '大学之门';
      final engine = VerbatimCollation();
      final changes = engine.compare(text1, text2);

      final result = changes
          .map((c) {
            String typeStr;
            switch (c.type) {
              case CollationType.insert:
                typeStr = '[+]';
                break;
              case CollationType.delete:
                typeStr = '[-]';
                break;
              case CollationType.equal:
                typeStr = '[=]';
                break;
            }
            return '$typeStr ${c.text}';
          })
          .join('\n');

      expect(result, contains('[-] 道'));
      expect(result, contains('[+] 门'));
    });

    test('Verbatim with options logic', () {
      // Skip this test if OpenCC is not available (e.g., in some CI environments)
      if (TextNormalizer.openccStatus != OpenCCStatus.available) {
        print('SKIPPING OpenCC test - not available');
        return;
      }

      final text1 = '學而時習之';
      final text2 = '学而时习之';
      final options = CollationOptions(ignoreTraditional: true);
      final engine = VerbatimCollation();
      final changes = engine.compare(text1, text2, options: options);

      expect(changes.length, 1);
      expect(changes[0].type, CollationType.equal);
      expect(changes[0].text, '学而时习之');
    });

    test('Statistical analysis logic', () {
      final text1 = '大学之道在明明得';
      final text2 = '大学之道在明明德';
      final engine = VerbatimCollation();
      final changes = engine.compare(text1, text2);

      final similarity = SimilarityScorer.calculate(changes);
      final patterns = ChangePatternAnalyzer.analyze(changes);

      expect(similarity, closeTo(0.875, 0.001));
      expect(patterns['得->德'], 1);
    });

    test('Structural comparison logic', () {
      final file1 = File(doc1Path);
      final file2 = File(doc2Path);

      final doc1Json = jsonDecode(file1.readAsStringSync());
      final doc2Json = jsonDecode(file2.readAsStringSync());

      final doc1 = _parseDoc(doc1Json);
      final doc2 = _parseDoc(doc2Json);

      final engine = StructuralCollation();
      final diffs = engine.compareDocuments(doc1, doc2);
      final patch = JsonPatchConverter.convert(diffs);

      final patchStr = jsonEncode(patch);
      expect(patchStr, contains('"op":"replace"'));
      expect(patchStr, contains('"path":"/chapters/0/title"'));
    });
  });
}

Document _parseDoc(dynamic json) {
  final chapters = (json['chapters'] as List).map((c) {
    final paragraphs = (c['paragraphs'] as List).map((p) {
      return Paragraph(
        id: p['id']?.toString() ?? '',
        content: p['content'] ?? '',
      );
    }).toList();
    return Chapter(title: c['title'] ?? '', paragraphs: paragraphs);
  }).toList();
  return Document(chapters: chapters);
}
