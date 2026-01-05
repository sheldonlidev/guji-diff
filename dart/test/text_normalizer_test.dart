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

    test('Traditional to Simplified conversion (Fallback Map)', () {
      final input = '學而時習之';
      // In cloud environment, this should use the fallback map
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: false,
        ignoreTraditional: true,
        ignoreVariants: false,
      );
      expect(output, '学而时习之');
    });

    test('Variant mapping', () {
      final input = '箇中灋盃羣';
      final output = TextNormalizer.normalize(
        input,
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: true,
      );
      expect(output, '个中法杯群');
    });
  });
}
