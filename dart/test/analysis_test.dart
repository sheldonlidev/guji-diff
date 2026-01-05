import 'package:flutter_test/flutter_test.dart';
import 'package:guji_diff/guji_diff.dart';

void main() {
  group('Analysis Tests', () {
    final engine = VerbatimCollation();

    test('Similarity Score Test', () {
      final text1 = '大学之道在明明德';
      final text2 = '大学之道在明明德';
      expect(SimilarityScorer.calculate(engine.compare(text1, text2)), 1.0);

      final t1 = 'ABC';
      final t2 = 'ADC'; // B -> D
      // L1=3, L2=3, M=2 (A, C) -> (2*2)/(3+3) = 4/6 = 0.666...
      expect(
        SimilarityScorer.calculate(engine.compare(t1, t2)),
        closeTo(0.66, 0.01),
      );
    });

    test('Pattern Recognition Test', () {
      // 场景：多次将 "其" 误作为 "期"
      final text1 = '其人其事其心';
      final text2 = '期人期事期心';

      final changes = engine.compare(text1, text2);
      final patterns = ChangePatternAnalyzer.analyze(changes);

      // 注意：由于 diff-match-patch 的分块特性，
      // 如果 '其人其事其' 被合并，我们的解析器需要能够识别这种模式。
      // 目前的简单解析可能识别为 '其人其事其' -> '期人期事期'
      // 现在采用了 Sub-diff 逻辑，应该能从合并的大块中提取出 3 次 '其->期'
      expect(patterns['其->期'], 3);
    });
  });
}
