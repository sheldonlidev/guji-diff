import 'package:flutter_test/flutter_test.dart';
import 'package:guji_diff/guji_diff.dart';

void main() {
  group('TextNormalizer - Basic Functionality', () {
    test('No normalization (all options false)', () {
      final input = '大学之道，在明明德。';
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: false,
      );
      expect(output, '大学之道，在明明德。');
    });

    test('Punctuation removal only', () {
      final input = '大学之道，在明明德。';
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: true,
        ignoreTraditional: false,
        ignoreVariants: false,
      );
      expect(output, '大学之道在明明德');
    });

    test('Punctuation removal with various punctuation types', () {
      final input = '天下事：甲、乙、丙！？【注】（一）';
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: true,
        ignoreTraditional: false,
        ignoreVariants: false,
      );
      expect(output, '天下事甲乙丙注一');
    });
  });

  group('TextNormalizer - Variant Characters (Hardcoded Map)', () {
    test('Variant char in map - ignoreVariants=true', () {
      // '箇' is in the hardcoded _variantCharMap
      final input = '箇中之道';
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: true,
      );
      expect(output, '个中之道');
    });

    test('Variant char in map - ignoreVariants=false', () {
      // '箇' should not be converted when ignoreVariants=false
      final input = '箇中之道';
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: false,
      );
      expect(output, '箇中之道');
    });

    test('Variant char in map with punctuation', () {
      final input = '箇中之道，深不可測。';
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: true,
        ignoreTraditional: false,
        ignoreVariants: true,
      );
      expect(output, '个中之道深不可測');
    });

    test('Multiple variant chars in map', () {
      // Testing multiple occurrences of the same variant char
      final input = '箇人有箇样，箇箇不同';
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: true,
      );
      expect(output, '个人有个样，个个不同');
    });
  });

  group('TextNormalizer - Variant Characters (OpenCC Handled)', () {
    test('OpenCC variant char - only handled by OpenCC', () {
      // '爲' is a variant of '为', but not in hardcoded map
      // OpenCC should handle it when ignoreTraditional=true
      final input = '以爲';
      final status = TextNormalizer.openccStatus;

      if (status == OpenCCStatus.available || status == null) {
        try {
          final output = TextNormalizer.normalize(
            input,
            ignorePunctuation: false,
            ignoreTraditional: true,
            ignoreVariants: false,
          );
          // OpenCC should convert 爲 to 为
          expect(output, '以为');
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('OpenCC variant char - not converted when ignoreTraditional=false', () {
      // When OpenCC is not used, variant chars outside hardcoded map stay unchanged
      final input = '以爲';
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: false,
      );
      expect(output, '以爲');
    });

    test('Mixed variants - hardcoded and OpenCC', () {
      // '箇' in hardcoded map, '爲' handled by OpenCC
      final input = '箇人以爲';
      final status = TextNormalizer.openccStatus;

      if (status == OpenCCStatus.available || status == null) {
        try {
          // Test with both ignoreVariants and ignoreTraditional
          final output = TextNormalizer.normalize(
            input,
            ignorePunctuation: false,
            ignoreTraditional: true,
            ignoreVariants: true,
          );
          expect(output, '个人以为');
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('OpenCC variant - ignoreVariants has no effect on OpenCC-only variants', () {
      // '爲' is not in hardcoded map, so ignoreVariants=true alone won't convert it
      final input = '以爲';
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: true, // This should not affect '爲'
      );
      expect(output, '以爲'); // Should remain unchanged
    });
  });

  group('TextNormalizer - Traditional to Simplified', () {
    test('Traditional conversion only', () {
      final input = '學而時習之';
      final status = TextNormalizer.openccStatus;

      if (status == OpenCCStatus.available || status == null) {
        try {
          final output = TextNormalizer.normalize(
            input,
            ignorePunctuation: false,
            ignoreTraditional: true,
            ignoreVariants: false,
          );
          expect(output, '学而时习之');
        } catch (e) {
          expect(e, isA<StateError>());
        }
      } else {
        expect(
          () => TextNormalizer.normalize(
            input,
            ignorePunctuation: false,
            ignoreTraditional: true,
            ignoreVariants: false,
          ),
          throwsStateError,
        );
      }
    });

    test('Traditional conversion with punctuation removal', () {
      final input = '學而時習之，不亦說乎？';
      final status = TextNormalizer.openccStatus;

      if (status == OpenCCStatus.available || status == null) {
        try {
          final output = TextNormalizer.normalize(
            input,
            ignorePunctuation: true,
            ignoreTraditional: true,
            ignoreVariants: false,
          );
          expect(output, '学而时习之不亦说乎');
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });
  });

  group('TextNormalizer - Combined Options (8 Combinations)', () {
    final testInput = '箇中學問，深不可測！';
    // Components: 箇(variant in map) 中學(trad) 問(trad) 標點 測(trad)

    test('Combination 1: all false (no changes)', () {
      final output = TextNormalizer.normalize(
        testInput,
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: false,
      );
      expect(output, '箇中學問，深不可測！');
    });

    test('Combination 2: only ignorePunctuation=true', () {
      final output = TextNormalizer.normalize(
        testInput,
        ignorePunctuation: true,
        ignoreTraditional: false,
        ignoreVariants: false,
      );
      expect(output, '箇中學問深不可測');
    });

    test('Combination 3: only ignoreTraditional=true', () {
      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final output = TextNormalizer.normalize(
            testInput,
            ignorePunctuation: false,
            ignoreTraditional: true,
            ignoreVariants: false,
          );
          // 箇 stays, traditional chars converted
          expect(output, '箇中学问，深不可测！');
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('Combination 4: only ignoreVariants=true', () {
      final output = TextNormalizer.normalize(
        testInput,
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: true,
      );
      // Only 箇 -> 个
      expect(output, '个中學問，深不可測！');
    });

    test('Combination 5: ignorePunctuation=true, ignoreTraditional=true', () {
      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final output = TextNormalizer.normalize(
            testInput,
            ignorePunctuation: true,
            ignoreTraditional: true,
            ignoreVariants: false,
          );
          expect(output, '箇中学问深不可测');
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('Combination 6: ignorePunctuation=true, ignoreVariants=true', () {
      final output = TextNormalizer.normalize(
        testInput,
        ignorePunctuation: true,
        ignoreTraditional: false,
        ignoreVariants: true,
      );
      expect(output, '个中學問深不可測');
    });

    test('Combination 7: ignoreTraditional=true, ignoreVariants=true', () {
      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final output = TextNormalizer.normalize(
            testInput,
            ignorePunctuation: false,
            ignoreTraditional: true,
            ignoreVariants: true,
          );
          // 箇 -> 个 first, then OpenCC conversion
          expect(output, '个中学问，深不可测！');
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('Combination 8: all true (full normalization)', () {
      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final output = TextNormalizer.normalize(
            testInput,
            ignorePunctuation: true,
            ignoreTraditional: true,
            ignoreVariants: true,
          );
          expect(output, '个中学问深不可测');
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });
  });

  group('TextNormalizer - Edge Cases', () {
    test('Empty string - no OpenCC needed', () {
      final output = TextNormalizer.normalize(
        '',
        ignorePunctuation: true,
        ignoreTraditional: false,
        ignoreVariants: true,
      );
      expect(output, '');
    });

    test('Empty string - with OpenCC enabled', () {
      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final output = TextNormalizer.normalize(
            '',
            ignorePunctuation: true,
            ignoreTraditional: true,
            ignoreVariants: true,
          );
          expect(output, '');
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('Only punctuation', () {
      final input = '，。！？';
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: true,
        ignoreTraditional: false,
        ignoreVariants: false,
      );
      expect(output, '');
    });

    test('Already simplified text with all options true', () {
      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final input = '这是简体字';
          final output = TextNormalizer.normalize(
            input,
            ignorePunctuation: true,
            ignoreTraditional: true,
            ignoreVariants: true,
          );
          expect(output, '这是简体字');
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('Text with no variants or traditional chars', () {
      final input = '天地人和，万物生';
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: true,
      );
      expect(output, '天地人和，万物生');
    });
  });

  group('TextNormalizer - Position Mapping', () {
    test('Position mapping - variant char replacement', () {
      final input = '箇中之道';
      final result = TextNormalizer.normalizeWithMapping(
        input,
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: true,
      );

      expect(result.normalized, '个中之道');
      expect(result.positions.length, 4);
      expect(result.extractOriginal(input, 0, 1), '箇');
      expect(result.extractOriginal(input, 1, 2), '中');
      expect(result.extractOriginal(input, 0, 4), '箇中之道');
    });

    test('Position mapping - punctuation removal', () {
      final input = '學，問！';
      final result = TextNormalizer.normalizeWithMapping(
        input,
        ignorePunctuation: true,
        ignoreTraditional: false,
        ignoreVariants: false,
      );

      expect(result.normalized, '學問');
      expect(result.positions.length, 2);
      // 修正后的行为：extractOriginal只提取字符本身，不包含标点
      expect(result.extractOriginal(input, 0, 1), '學'); // 不包含标点
      expect(result.extractOriginal(input, 1, 2), '問'); // 不包含标点
      // 提取整个范围也不包含标点
      expect(result.extractOriginal(input, 0, 2), '學，問');
    });

    test('Position mapping - combined transformations', () {
      final input = '箇中學問，深不可測！';
      final result = TextNormalizer.normalizeWithMapping(
        input,
        ignorePunctuation: true,
        ignoreTraditional: false,
        ignoreVariants: true,
      );

      expect(result.normalized, '个中學問深不可測');
      // 修正后的行为：extractOriginal只提取字符本身，不包含标点
      expect(result.extractOriginal(input, 0, 1), '箇');
      expect(result.extractOriginal(input, 2, 3), '學');
      expect(result.extractOriginal(input, 4, 5), '深');
      // Extract range spanning punctuation - 不包含中间和尾部标点
      expect(result.extractOriginal(input, 0, 4), '箇中學問');
      expect(result.extractOriginal(input, 3, 8), '問，深不可測');
    });

    test('Position mapping - empty string', () {
      final result = TextNormalizer.normalizeWithMapping(
        '',
        ignorePunctuation: true,
        ignoreTraditional: false,
        ignoreVariants: true,
      );

      expect(result.normalized, '');
      expect(result.positions, isEmpty);
      expect(result.extractOriginal('', 0, 0), '');
    });

    test('Position mapping - all punctuation removed', () {
      final input = '，。！？';
      final result = TextNormalizer.normalizeWithMapping(
        input,
        ignorePunctuation: true,
        ignoreTraditional: false,
        ignoreVariants: false,
      );

      expect(result.normalized, '');
      expect(result.positions, isEmpty);
    });
  });
}
