import 'package:flutter_test/flutter_test.dart';
import 'package:guji_diff/guji_diff.dart';

void main() {
  group('VerbatimCollation Tests', () {
    final engine = VerbatimCollation();

    test('Basic string comparison', () {
      final text1 = '大学之道在明明得';
      final text2 = '大学之道在明明德';
      final changes = engine.compare(text1, text2);

      expect(
        changes.any((c) => c.type == CollationType.delete && c.text == '得'),
        isTrue,
      );
      expect(
        changes.any((c) => c.type == CollationType.insert && c.text == '德'),
        isTrue,
      );
    });

    test('Identity comparison', () {
      final text = '大学之道，在明明德，在亲民，在止于至善。';
      final changes = engine.compare(text, text);

      expect(changes.length, 1);
      expect(changes[0].type, CollationType.equal);
      expect(changes[0].text, text);
    });

    test('Empty to non-empty (Pure Addition)', () {
      final text1 = '';
      final text2 = '大学之道';
      final changes = engine.compare(text1, text2);

      expect(changes.length, 1);
      expect(changes[0].type, CollationType.insert);
      expect(changes[0].text, '大学之道');
    });

    test('Non-empty to empty (Pure Deletion)', () {
      final text1 = '大学之道';
      final text2 = '';
      final changes = engine.compare(text1, text2);

      expect(changes.length, 1);
      expect(changes[0].type, CollationType.delete);
      expect(changes[0].text, '大学之道');
    });

    test('Changing 3 characters to 5 characters', () {
      final text1 = '一二三';
      final text2 = '一甲乙丙三'; // Character replacement in middle + expansion
      final changes = engine.compare(text1, text2);

      // Verify "二" is deleted and "甲乙丙" is inserted
      expect(
        changes.any((c) => c.type == CollationType.delete && c.text == '二'),
        isTrue,
      );
      expect(
        changes.any((c) => c.type == CollationType.insert && c.text == '甲乙丙'),
        isTrue,
      );
    });

    test('Complex modification (CRUD equivalent)', () {
      final text1 = 'ABC';
      final text2 = 'AXDY'; // B deleted, C replaced by XDY? Or B->XD, C->Y?
      final changes = engine.compare(text1, text2);

      // We mainly want to ensure no crash and logical segments
      expect(
        changes.where((c) => c.type == CollationType.equal).length,
        greaterThan(0),
      );
      expect(
        changes.where((c) => c.type == CollationType.delete).length,
        greaterThan(0),
      );
      expect(
        changes.where((c) => c.type == CollationType.insert).length,
        greaterThan(0),
      );
    });
  });
}
