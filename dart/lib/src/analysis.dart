import 'package:diff_match_patch/diff_match_patch.dart';
import 'verbatim_collation.dart';

/// 统计分析报告模型
class AnalysisReport {
  final double similarity;
  final Map<String, int> patterns;
  final int totalChanges;

  AnalysisReport({
    required this.similarity,
    required this.patterns,
    required this.totalChanges,
  });

  Map<String, dynamic> toJson() => {
    'similarity': similarity,
    'patterns': patterns,
    'totalChanges': totalChanges,
  };
}

/// 相似度评分器
class SimilarityScorer {
  /// 计算两个文本的相似度 (0.0 to 1.0)
  static double calculate(List<CollationChange> changes) {
    if (changes.isEmpty) return 1.0;

    // 我们采用一种常用公式：2 * M / (L1 + L2)
    // M 是匹配字符数
    // L1 = equal + delete, L2 = equal + insert
    int equalCount = 0;
    int l1 = 0;
    int l2 = 0;
    for (var change in changes) {
      if (change.type == CollationType.equal) {
        final len = change.text.length;
        equalCount += len;
        l1 += len;
        l2 += len;
      } else if (change.type == CollationType.delete) {
        l1 += change.text.length;
      } else if (change.type == CollationType.insert) {
        l2 += change.text.length;
      }
    }

    if (l1 + l2 == 0) return 1.0;
    return (2.0 * equalCount) / (l1 + l2);
  }
}

/// 改动模式分析器
class ChangePatternAnalyzer {
  /// 识别高频改动模式 (例如：A -> B)
  static Map<String, int> analyze(List<CollationChange> changes) {
    final patterns = <String, int>{};
    final dmp = DiffMatchPatch();

    for (var i = 0; i < changes.length - 1; i++) {
      final current = changes[i];
      final next = changes[i + 1];

      // 典型的替换模式是 Delete 后紧跟 Insert
      if (current.type == CollationType.delete &&
          next.type == CollationType.insert) {
        // 为了处理 DMP 可能将多个改动合并为一个大块的情况（如 '其人其事其' -> '期人期事期'）
        // 我们对 delete 和 insert 的内容进行二次比对 (Sub-diff)
        final subDiffs = dmp.diff(current.text, next.text);
        // Do NOT use cleanup for sub-diff to keep maximum granularity for pattern recognition
        // dmp.diffCleanupSemantic(subDiffs);

        for (var j = 0; j < subDiffs.length - 1; j++) {
          final s1 = subDiffs[j];
          final s2 = subDiffs[j + 1];

          // DIFF_DELETE is -1, DIFF_INSERT is 1
          if (s1.operation == -1 && s2.operation == 1) {
            final pattern = '${s1.text}->${s2.text}';
            patterns[pattern] = (patterns[pattern] ?? 0) + 1;
            j++;
          }
        }
        i++; // 跳过已处理的 pairs
      }
    }

    return patterns;
  }
}
