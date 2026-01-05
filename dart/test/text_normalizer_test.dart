import 'package:flutter_test/flutter_test.dart';
import 'package:guji_diff/guji_diff.dart';

void main() {
  group('TextNormalizer Tests', () {
    test('Punctuation removal', () {
      final input = '大学之道，在明明德。';
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: true,
        ignoreTraditional: false,
        ignoreVariants: false,
      );
      expect(output, '大学之道在明明德');
    });

    test('Traditional to Simplified conversion (requires OpenCC)', () {
      final input = '學而時習之';

      // 检查 OpenCC 是否可用
      final status = TextNormalizer.openccStatus;

      if (status == OpenCCStatus.available || status == null) {
        // 如果 OpenCC 可用，应该能正常转换
        try {
          final output = TextNormalizer.normalize(
            input,
            ignorePunctuation: false,
            ignoreTraditional: true,
            ignoreVariants: false,
          );
          expect(output, '学而时习之');
        } catch (e) {
          // 如果抛出异常，说明 OpenCC 不可用
          expect(e, isA<StateError>());
          expect(
            e.toString(),
            contains('OpenCC native library is not available'),
          );
        }
      } else {
        // OpenCC 不可用，应该抛出异常
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

    test('Variant mapping (without OpenCC)', () {
      final input = '箇中之道';
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: true,
      );
      expect(output, '个中之道');
    });

    test('Variant mapping combined with Traditional conversion', () {
      final input = '箇中學問';

      // 检查 OpenCC 是否可用
      final status = TextNormalizer.openccStatus;

      if (status == OpenCCStatus.available || status == null) {
        try {
          final output = TextNormalizer.normalize(
            input,
            ignorePunctuation: false,
            ignoreTraditional: true,
            ignoreVariants: true,
          );
          // 箇 -> 个 (variant mapping), 學 -> 学 (OpenCC)
          expect(output, '个中学问');
        } catch (e) {
          // OpenCC 不可用时会抛出异常
          expect(e, isA<StateError>());
        }
      }
    });
  });
}
