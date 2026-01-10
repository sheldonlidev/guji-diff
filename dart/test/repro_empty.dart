import 'package:guji_diff/src/text_normalizer.dart';

void main() {
  print('Running repro...');
  try {
    final result = TextNormalizer.normalizeWithMapping(
      '',
      ignorePunctuation: true,
      ignoreTraditional: false,
      ignoreVariants: true,
    );

    print('Normalized: "${result.normalized}"');
    print('Positions len: ${result.positions.length}');

    final extracted = result.extractOriginal('', 0, 0);
    print('Extracted: "$extracted"');

    if (extracted != '') throw Exception('Expected empty string');
    print('Success!');
  } catch (e, s) {
    print('Error: $e');
    print('Stack: $s');
  }
}
