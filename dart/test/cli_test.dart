import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CLI Tool Tests', () {
    const cliPath = 'bin/guji_diff.dart';
    const doc1Path = 'test/temp_doc1.json';
    const doc2Path = 'test/temp_doc2.json';

    setUp(() {
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

    test('Verbatim comparison via CLI', () async {
      final result = await Process.run('dart', [
        'run',
        cliPath,
        '大学之道',
        '大学之门',
      ], stdoutEncoding: utf8);

      expect(result.exitCode, 0);
      final stdout = result.stdout.toString();
      expect(stdout, contains('Verbatim Collation Results:'));
      expect(stdout, contains('[-] 道'));
      expect(stdout, contains('[+] 门'));
    });

    test('Verbatim with options via CLI', () async {
      final result = await Process.run('dart', [
        'run',
        cliPath,
        '學而時習之',
        '学而时习之',
        '--ignore-traditional',
      ], stdoutEncoding: utf8);

      expect(result.exitCode, 0);
      final stdout = result.stdout.toString();
      expect(stdout, contains('[=] 学而时习之'));
    });

    test('Statistical analysis via CLI', () async {
      final result = await Process.run('dart', [
        'run',
        cliPath,
        '大学之道在明明得',
        '大学之道在明明德',
        '--analyze',
      ], stdoutEncoding: utf8);

      expect(result.exitCode, 0);
      final stdout = result.stdout.toString();
      expect(stdout, contains('Statistical Analysis Report (JSON):'));
      expect(stdout, contains('"similarity": 0.875'));
      expect(stdout, contains('"得->德": 1'));
    });

    test('Structural comparison via CLI', () async {
      final result = await Process.run('dart', [
        'run',
        cliPath,
        doc1Path,
        doc2Path,
        '--structural',
      ], stdoutEncoding: utf8);

      expect(result.exitCode, 0);
      final stdout = result.stdout.toString();
      expect(stdout, contains('Structural Collation Results (JSON Patch):'));
      expect(stdout, contains('"op": "replace"'));
      expect(stdout, contains('"path": "/chapters/0/title"'));
    });
  });
}
