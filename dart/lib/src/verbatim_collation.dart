import 'package:diff_match_patch/diff_match_patch.dart';
import 'collation_options.dart';
import 'text_normalizer.dart';

/// 表示校勘差异的类型
enum CollationType { insert, delete, equal }

/// 表示校勘中的一个变更片段
class CollationChange {
  final CollationType type;
  final String text;

  const CollationChange({required this.type, required this.text});

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

  /// 对齐 diff 中的换行符
  /// 当删除和插入内容中都包含换行符时，强制将换行符对齐为 EQUAL
  void _alignNewlines(List<Diff> diffs) {
    final result = <Diff>[];
    int i = 0;

    while (i < diffs.length) {
      if (diffs[i].operation == DIFF_EQUAL) {
        result.add(diffs[i]);
        i++;
        continue;
      }

      // 发现非 EQUAL 块，收集连续的 DELETE 和 INSERT
      final block = <Diff>[];
      while (i < diffs.length && diffs[i].operation != DIFF_EQUAL) {
        block.add(diffs[i]);
        i++;
      }

      // 提取删除和插入的文本
      final delBuffer = StringBuffer();
      final insBuffer = StringBuffer();
      for (final d in block) {
        if (d.operation == DIFF_DELETE) delBuffer.write(d.text);
        if (d.operation == DIFF_INSERT) insBuffer.write(d.text);
      }
      final delText = delBuffer.toString();
      final insText = insBuffer.toString();

      // 只有当两边都有换行符时才进行对齐处理
      if (delText.contains('\n') && insText.contains('\n')) {
        final delParts = delText.split('\n');
        final insParts = insText.split('\n');
        final count = delParts.length > insParts.length
            ? delParts.length
            : insParts.length;

        for (int k = 0; k < count; k++) {
          final dPart = k < delParts.length ? delParts[k] : null;
          final iPart = k < insParts.length ? insParts[k] : null;

          // 添加文本部分
          if (dPart != null && dPart.isNotEmpty) {
            result.add(Diff(DIFF_DELETE, dPart));
          }
          if (iPart != null && iPart.isNotEmpty) {
            result.add(Diff(DIFF_INSERT, iPart));
          }

          // 是否还有后续部分（意味着当前部分后面有换行符）
          final hasDelSep = k < delParts.length - 1;
          final hasInsSep = k < insParts.length - 1;

          if (hasDelSep && hasInsSep) {
            result.add(Diff(DIFF_EQUAL, '\n'));
          } else if (hasDelSep) {
            result.add(Diff(DIFF_DELETE, '\n'));
          } else if (hasInsSep) {
            result.add(Diff(DIFF_INSERT, '\n'));
          }
        }
      } else {
        // 不需要对齐，保持原样
        result.addAll(block);
      }
    }

    diffs.clear();
    diffs.addAll(result);
  }

  /// 自定义的 diff 清理方法，确保换行符始终保持独立
  /// 这个方法会在 diffCleanupSemantic 之后运行，拆分包含换行符的片段
  void _splitNewlines(List<Diff> diffs) {
    final result = <Diff>[];

    for (final diff in diffs) {
      final text = diff.text;

      // 如果文本不包含换行符，或只有一个换行符，直接添加
      if (!text.contains('\n') || text == '\n') {
        result.add(diff);
        continue;
      }

      // 如果文本包含换行符，需要拆分
      final parts = <String>[];
      int start = 0;

      for (int i = 0; i < text.length; i++) {
        if (text[i] == '\n') {
          // 添加换行符之前的内容（如果有）
          if (i > start) {
            parts.add(text.substring(start, i));
          }
          // 添加换行符本身
          parts.add('\n');
          start = i + 1;
        }
      }

      // 添加最后剩余的内容（如果有）
      if (start < text.length) {
        parts.add(text.substring(start));
      }

      // 将所有部分作为独立的 diff 添加
      for (final part in parts) {
        result.add(Diff(diff.operation, part));
      }
    }

    // 清空原列表并添加拆分后的结果
    diffs.clear();
    diffs.addAll(result);
  }

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
    _alignNewlines(diffs); // 对齐换行符
    _splitNewlines(diffs); // 确保换行符独立

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
    _alignNewlines(diffs); // 对齐换行符
    _splitNewlines(diffs); // 确保换行符独立

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
              ? norm1.extractOriginal(
                  text1,
                  pos1,
                  (pos1 + length).clamp(0, norm1.positions.length),
                )
              : '';
          final text2Original = length > 0
              ? norm2.extractOriginal(
                  text2,
                  pos2,
                  (pos2 + length).clamp(0, norm2.positions.length),
                )
              : '';

          // Text1视图：EQUAL（保留）
          text1View.add(
            CollationChange(type: CollationType.equal, text: text1Original),
          );

          // Text2视图：EQUAL（保留）
          text2View.add(
            CollationChange(type: CollationType.equal, text: text2Original),
          );

          // Merged视图：使用text1的原文
          mergedView.add(
            CollationChange(type: CollationType.equal, text: text1Original),
          );

          pos1 += length;
          pos2 += length;
          break;

        case DIFF_DELETE:
          // 提取text1的原文
          final text1Original = length > 0
              ? norm1.extractOriginal(
                  text1,
                  pos1,
                  (pos1 + length).clamp(0, norm1.positions.length),
                )
              : '';

          // Text1视图：DELETE（被删除）
          text1View.add(
            CollationChange(type: CollationType.delete, text: text1Original),
          );

          // Text2视图：不添加（因为text2中没有这部分）

          // Merged视图：DELETE
          mergedView.add(
            CollationChange(type: CollationType.delete, text: text1Original),
          );

          pos1 += length;
          break;

        case DIFF_INSERT:
          // 提取text2的原文
          final text2Original = length > 0
              ? norm2.extractOriginal(
                  text2,
                  pos2,
                  (pos2 + length).clamp(0, norm2.positions.length),
                )
              : '';

          // Text1视图：不添加（因为text1中没有这部分）

          // Text2视图：INSERT（新增）
          text2View.add(
            CollationChange(type: CollationType.insert, text: text2Original),
          );

          // Merged视图：INSERT
          mergedView.add(
            CollationChange(type: CollationType.insert, text: text2Original),
          );

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
          result.add(
            CollationChange(type: CollationType.equal, text: originalText),
          );
          pos1 += length;
          pos2 += length;
          break;

        case DIFF_DELETE:
          // 提取text1的原文
          final originalText = length > 0
              ? norm1.extractOriginal(originalText1, pos1, pos1 + length)
              : '';
          result.add(
            CollationChange(type: CollationType.delete, text: originalText),
          );
          pos1 += length;
          break;

        case DIFF_INSERT:
          // 提取text2的原文
          final originalText = length > 0
              ? norm2.extractOriginal(
                  originalText2,
                  pos2,
                  (pos2 + length).clamp(0, norm2.positions.length),
                )
              : '';
          result.add(
            CollationChange(type: CollationType.insert, text: originalText),
          );
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
    _alignNewlines(diffs); // 对齐换行符
    _splitNewlines(diffs); // 确保换行符独立

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
