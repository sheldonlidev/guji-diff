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

  group('VerbatimCollation - Original Text Preservation', () {
    final engine = VerbatimCollation();

    test('EQUAL segment shows text1 original form', () {
      final text1 = '箇中學問';
      final text2 = '个中学问';
      final options = CollationOptions(
        ignorePunctuation: false,
        ignoreTraditional: true,
        ignoreVariants: true,
      );

      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final changes = engine.compare(text1, text2, options: options);

          // Should normalize to same text, showing text1's original
          expect(changes.length, 1);
          expect(changes[0].type, CollationType.equal);
          expect(changes[0].text, '箇中學問'); // NOT '个中学问'
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('DELETE segment shows text1 original form', () {
      final text1 = '箇中學問';
      final text2 = '箇中';
      final options = CollationOptions(
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: true,
      );

      final changes = engine.compare(text1, text2, options: options);

      final deleteChange = changes.firstWhere((c) => c.type == CollationType.delete);
      expect(deleteChange.text, '學問'); // Original form from text1
    });

    test('INSERT segment shows text2 original form', () {
      final text1 = '箇中';
      final text2 = '箇中學問';
      final options = CollationOptions(
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: true,
      );

      final changes = engine.compare(text1, text2, options: options);

      final insertChange = changes.firstWhere((c) => c.type == CollationType.insert);
      expect(insertChange.text, '學問'); // Original form from text2
    });

    test('Punctuation preserved in EQUAL segment', () {
      final text1 = '學，問！';
      final text2 = '学问';
      final options = CollationOptions(
        ignorePunctuation: true,
        ignoreTraditional: true,
        ignoreVariants: false,
      );

      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final changes = engine.compare(text1, text2, options: options);

          // Should match (ignoring punctuation and traditional)
          expect(changes.length, 1);
          expect(changes[0].type, CollationType.equal);
          expect(changes[0].text, '學，問！'); // Shows text1 with punctuation
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('Mixed scenario - EQUAL, DELETE, INSERT preserve originals', () {
      final text1 = '箇中學問，深不可測！';
      final text2 = '个中学道深不可测';
      final options = CollationOptions(
        ignorePunctuation: true,
        ignoreTraditional: true,
        ignoreVariants: true,
      );

      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final changes = engine.compare(text1, text2, options: options);

          // Find segments
          final equalSegments = changes.where((c) => c.type == CollationType.equal).toList();
          final deleteSegments = changes.where((c) => c.type == CollationType.delete).toList();
          final insertSegments = changes.where((c) => c.type == CollationType.insert).toList();

          // EQUAL segments should show text1's original (with variants, traditional, punctuation)
          expect(equalSegments.isNotEmpty, isTrue);
          for (final seg in equalSegments) {
            // Should contain text1's original characters
            expect(text1.contains(seg.text) || seg.text.split('').every((c) => text1.contains(c)), isTrue);
          }

          // DELETE should show text1's original
          if (deleteSegments.isNotEmpty) {
            for (final seg in deleteSegments) {
              expect(seg.text, isNot(contains('个'))); // Should have 箇 if it's the variant
            }
          }

          // INSERT should show text2's original
          if (insertSegments.isNotEmpty) {
            for (final seg in insertSegments) {
              expect(text2.contains(seg.text.replaceAll(RegExp(r'[，！]'), '')), isTrue);
            }
          }
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('Empty strings handled correctly', () {
      final options = CollationOptions(
        ignorePunctuation: true,
        ignoreTraditional: true,
        ignoreVariants: true,
      );

      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final changes = engine.compare('', '', options: options);
          expect(changes.length, 1);
          expect(changes[0].type, CollationType.equal);
          expect(changes[0].text, '');
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('INSERT preserves text2 punctuation even when ignorePunctuation=true', () {
      final text1 = '箇中學';
      final text2 = '箇中學問，深！';
      final options = CollationOptions(
        ignorePunctuation: true,
        ignoreTraditional: false,
        ignoreVariants: true,
      );

      final changes = engine.compare(text1, text2, options: options);

      // Find the INSERT segment
      final insertChange = changes.firstWhere(
        (c) => c.type == CollationType.insert,
        orElse: () => CollationChange(type: CollationType.equal, text: ''),
      );

      // INSERT should show text2's original with internal punctuation preserved
      // but not trailing punctuation that follows the last normalized character
      expect(insertChange.text, '問，深');
      expect(insertChange.text, contains('，')); // Contains comma (internal)
      expect(insertChange.text.contains('！'), isFalse); // Does NOT contain trailing punctuation
    });

    test('INSERT preserves text2 traditional chars even when ignoreTraditional=true', () {
      final text1 = '个中';
      final text2 = '个中學問';
      final options = CollationOptions(
        ignorePunctuation: false,
        ignoreTraditional: true,
        ignoreVariants: false,
      );

      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final changes = engine.compare(text1, text2, options: options);

          // Find the INSERT segment
          final insertChange = changes.firstWhere(
            (c) => c.type == CollationType.insert,
            orElse: () => CollationChange(type: CollationType.equal, text: ''),
          );

          // INSERT should show text2's original traditional characters
          expect(insertChange.text, '學問'); // Traditional form from text2
          expect(insertChange.text, isNot(contains('学'))); // NOT simplified
          expect(insertChange.text, isNot(contains('问'))); // NOT simplified
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('INSERT preserves text2 variant chars even when ignoreVariants=true', () {
      final text1 = '个中';
      final text2 = '个中箇人';
      final options = CollationOptions(
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: true,
      );

      final changes = engine.compare(text1, text2, options: options);

      // Find the INSERT segment
      final insertChange = changes.firstWhere(
        (c) => c.type == CollationType.insert,
        orElse: () => CollationChange(type: CollationType.equal, text: ''),
      );

      // INSERT should show text2's original variant character
      expect(insertChange.text, '箇人'); // Variant form from text2
      expect(insertChange.text, contains('箇')); // Contains variant char
    });

    test('INSERT preserves ALL text2 original features (punctuation + traditional + variants)', () {
      final text1 = '个中';
      final text2 = '个中箇學問，深！';
      final options = CollationOptions(
        ignorePunctuation: true,
        ignoreTraditional: true,
        ignoreVariants: true,
      );

      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final changes = engine.compare(text1, text2, options: options);

          // Find the INSERT segment
          final insertChange = changes.firstWhere(
            (c) => c.type == CollationType.insert,
            orElse: () => CollationChange(type: CollationType.equal, text: ''),
          );

          // INSERT should preserve ALL original features from text2
          expect(insertChange.text, '箇學問，深！');
          expect(insertChange.text, contains('箇')); // Variant preserved
          expect(insertChange.text, contains('學')); // Traditional preserved
          expect(insertChange.text, contains('，')); // Punctuation preserved
          expect(insertChange.text, contains('！')); // Punctuation preserved
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('EQUAL shows text1 form, but text2 originals preserved in non-EQUAL parts', () {
      // 验证：当text1和text2都有特殊字符时
      // - EQUAL段落显示text1的原始形式
      // - DELETE段落显示text1的原始形式
      // - INSERT段落显示text2的原始形式
      final text1 = '箇中學，問！';  // text1: 异体字+繁体+标点
      final text2 = '个中学道理？';  // text2: 简体+标点
      final options = CollationOptions(
        ignorePunctuation: true,
        ignoreTraditional: true,
        ignoreVariants: true,
      );

      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final changes = engine.compare(text1, text2, options: options);

          // 应该有: EQUAL(箇中學), DELETE(問！), INSERT(道理？)
          final equalSegments = changes.where((c) => c.type == CollationType.equal).toList();
          final deleteSegments = changes.where((c) => c.type == CollationType.delete).toList();
          final insertSegments = changes.where((c) => c.type == CollationType.insert).toList();

          // EQUAL显示text1的原始形式（包括异体字、繁体、标点）
          expect(equalSegments.isNotEmpty, isTrue);
          for (final seg in equalSegments) {
            // 应该包含text1的特征
            final hasText1Features = seg.text.contains('箇') || seg.text.contains('學');
            expect(hasText1Features, isTrue, reason: 'EQUAL应该显示text1的原始形式');
          }

          // DELETE显示text1的原始形式
          if (deleteSegments.isNotEmpty) {
            for (final seg in deleteSegments) {
              // DELETE的内容来自text1，应该保留text1的繁体字和标点
              final isFromText1 = text1.contains(seg.text) ||
                                  seg.text.split('').every((c) => text1.contains(c));
              expect(isFromText1, isTrue, reason: 'DELETE应该显示text1的原始形式');
            }
          }

          // INSERT显示text2的原始形式（包括text2的标点）
          if (insertSegments.isNotEmpty) {
            for (final seg in insertSegments) {
              // INSERT的内容来自text2，应该保留text2的简体字和标点
              final cleanSeg = seg.text.replaceAll(RegExp(r'[，！？]'), '');
              expect(text2.contains(cleanSeg), isTrue, reason: 'INSERT应该显示text2的原始形式');

              // 检查text2的标点是否被保留
              if (text2.contains('？')) {
                expect(seg.text, contains('？'), reason: 'INSERT应该保留text2的标点符号');
              }
            }
          }
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('Complex case - both texts have different punctuation and variants', () {
      // text1和text2在相同位置有不同的标点
      final text1 = '天地人和。';  // text1: 句号
      final text2 = '天地人和！';  // text2: 感叹号
      final options = CollationOptions(
        ignorePunctuation: true,
        ignoreTraditional: false,
        ignoreVariants: false,
      );

      final changes = engine.compare(text1, text2, options: options);

      // 忽略标点后应该完全相同，产生一个EQUAL段落
      expect(changes.length, 1);
      expect(changes[0].type, CollationType.equal);
      // EQUAL应该显示text1的原始形式（不包括尾部标点）
      expect(changes[0].text, '天地人和');  // 不包括尾部标点
    });
  });
}
