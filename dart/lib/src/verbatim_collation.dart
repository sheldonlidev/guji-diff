import 'package:diff_match_patch/diff_match_patch.dart';
import 'collation_options.dart';
import 'text_normalizer.dart';

/// 表示校勘差异的类型
enum CollationType { insert, delete, equal }

/// 表示校勘中的一个变更片段
class CollationChange {
  final CollationType type;
  final String text;

  CollationChange({required this.type, required this.text});

  @override
  String toString() => '${type.name}: $text';
}

/// 包含三种视图的完整对比结果
class FullCollationResult {
  /// Text1视图：标记了EQUAL（保留）和DELETE（被删除）的片段
  final List<CollationChange> text1View;

  /// Text2视图：标记了EQUAL（保留）和INSERT（新增）的片段
  final List<CollationChange> text2View;

  /// Merged视图：以text1为底本的对比结果（EQUAL用text1，DELETE用text1，INSERT用text2）
  final List<CollationChange> mergedView;

  FullCollationResult({
    required this.text1View,
    required this.text2View,
    required this.mergedView,
  });
}

/// 逐字校勘引擎
class VerbatimCollation {
  final DiffMatchPatch _dmp = DiffMatchPatch();

  /// 比较两个文本并返回差异列表
  List<CollationChange> compare(
    String text1,
    String text2, {
    CollationOptions options = CollationOptions.defaultOptions,
  }) {
    // 1. 获取带位置映射的归一化结果
    final norm1 = TextNormalizer.normalizeWithMapping(
      text1,
      ignorePunctuation: options.ignorePunctuation,
      ignoreTraditional: options.ignoreTraditional,
      ignoreVariants: options.ignoreVariants,
    );

    final norm2 = TextNormalizer.normalizeWithMapping(
      text2,
      ignorePunctuation: options.ignorePunctuation,
      ignoreTraditional: options.ignoreTraditional,
      ignoreVariants: options.ignoreVariants,
    );

    // 2. 在归一化文本上执行diff（算法不变）
    final diffs = _dmp.diff(norm1.normalized, norm2.normalized);
    _dmp.diffCleanupSemantic(diffs);

    // 3. 将diff结果映射回原文
    return _mapDiffsToOriginal(diffs, text1, text2, norm1, norm2);
  }

  /// 比较两个文本并返回包含三种视图的完整结果
  ///
  /// 返回的结果包含：
  /// - text1View: Text1视图，标记EQUAL（保留）和DELETE（被删除）
  /// - text2View: Text2视图，标记EQUAL（保留）和INSERT（新增）
  /// - mergedView: 合并视图，以text1为底本显示差异
  FullCollationResult compareWithFullContext(
    String text1,
    String text2, {
    CollationOptions options = CollationOptions.defaultOptions,
  }) {
    // 1. 获取带位置映射的归一化结果
    final norm1 = TextNormalizer.normalizeWithMapping(
      text1,
      ignorePunctuation: options.ignorePunctuation,
      ignoreTraditional: options.ignoreTraditional,
      ignoreVariants: options.ignoreVariants,
    );

    final norm2 = TextNormalizer.normalizeWithMapping(
      text2,
      ignorePunctuation: options.ignorePunctuation,
      ignoreTraditional: options.ignoreTraditional,
      ignoreVariants: options.ignoreVariants,
    );

    // 2. 在归一化文本上执行diff
    final diffs = _dmp.diff(norm1.normalized, norm2.normalized);
    _dmp.diffCleanupSemantic(diffs);

    // 3. 生成三种视图
    final text1View = <CollationChange>[];
    final text2View = <CollationChange>[];
    final mergedView = <CollationChange>[];

    int pos1 = 0; // 在归一化text1中的位置
    int pos2 = 0; // 在归一化text2中的位置

    for (final diff in diffs) {
      final length = diff.text.length;

      switch (diff.operation) {
        case DIFF_EQUAL:
          // 提取两个文本的原文
          final text1Original = length > 0
              ? norm1.extractOriginal(text1, pos1, pos1 + length)
              : '';
          final text2Original = length > 0
              ? norm2.extractOriginal(text2, pos2, pos2 + length)
              : '';

          // Text1视图：EQUAL（保留）
          text1View.add(CollationChange(
            type: CollationType.equal,
            text: text1Original,
          ));

          // Text2视图：EQUAL（保留）
          text2View.add(CollationChange(
            type: CollationType.equal,
            text: text2Original,
          ));

          // Merged视图：使用text1的原文
          mergedView.add(CollationChange(
            type: CollationType.equal,
            text: text1Original,
          ));

          pos1 += length;
          pos2 += length;
          break;

        case DIFF_DELETE:
          // 提取text1的原文
          final text1Original = length > 0
              ? norm1.extractOriginal(text1, pos1, pos1 + length)
              : '';

          // Text1视图：DELETE（被删除）
          text1View.add(CollationChange(
            type: CollationType.delete,
            text: text1Original,
          ));

          // Text2视图：不添加（因为text2中没有这部分）

          // Merged视图：DELETE
          mergedView.add(CollationChange(
            type: CollationType.delete,
            text: text1Original,
          ));

          pos1 += length;
          break;

        case DIFF_INSERT:
          // 提取text2的原文
          final text2Original = length > 0
              ? norm2.extractOriginal(text2, pos2, pos2 + length)
              : '';

          // Text1视图：不添加（因为text1中没有这部分）

          // Text2视图：INSERT（新增）
          text2View.add(CollationChange(
            type: CollationType.insert,
            text: text2Original,
          ));

          // Merged视图：INSERT
          mergedView.add(CollationChange(
            type: CollationType.insert,
            text: text2Original,
          ));

          pos2 += length;
          break;
      }
    }

    return FullCollationResult(
      text1View: text1View,
      text2View: text2View,
      mergedView: mergedView,
    );
  }

  /// 将diff结果映射回原始文本
  List<CollationChange> _mapDiffsToOriginal(
    List<Diff> diffs,
    String originalText1,
    String originalText2,
    NormalizationResult norm1,
    NormalizationResult norm2,
  ) {
    final result = <CollationChange>[];
    int pos1 = 0; // 在归一化text1中的位置
    int pos2 = 0; // 在归一化text2中的位置

    for (final diff in diffs) {
      final length = diff.text.length;

      switch (diff.operation) {
        case DIFF_EQUAL:
          // 提取text1的原文（用户要求：EQUAL显示text1版本）
          final originalText = length > 0
              ? norm1.extractOriginal(originalText1, pos1, pos1 + length)
              : '';
          result.add(CollationChange(
            type: CollationType.equal,
            text: originalText,
          ));
          pos1 += length;
          pos2 += length;
          break;

        case DIFF_DELETE:
          // 提取text1的原文
          final originalText = length > 0
              ? norm1.extractOriginal(originalText1, pos1, pos1 + length)
              : '';
          result.add(CollationChange(
            type: CollationType.delete,
            text: originalText,
          ));
          pos1 += length;
          break;

        case DIFF_INSERT:
          // 提取text2的原文
          final originalText = length > 0
              ? norm2.extractOriginal(originalText2, pos2, pos2 + length)
              : '';
          result.add(CollationChange(
            type: CollationType.insert,
            text: originalText,
          ));
          pos2 += length;
          break;
      }
    }

    return result;
  }

  /// 以 Unified Diff 格式输出（简化版）
  String toUnifiedDiff(String text1, String text2) {
    final s1 = TextNormalizer.normalize(
      text1,
      ignorePunctuation: false,
      ignoreTraditional: false,
      ignoreVariants: false,
    );
    final s2 = TextNormalizer.normalize(
      text2,
      ignorePunctuation: false,
      ignoreTraditional: false,
      ignoreVariants: false,
    );
    final diffs = _dmp.diff(s1, s2);
    _dmp.diffCleanupSemantic(diffs);

    final buffer = StringBuffer();
    for (var d in diffs) {
      if (d.operation == DIFF_INSERT) {
        buffer.write('[+] ${d.text}\n');
      } else if (d.operation == DIFF_DELETE) {
        buffer.write('[-] ${d.text}\n');
      } else {
        buffer.write('    ${d.text}\n');
      }
    }
    return buffer.toString();
  }
}
