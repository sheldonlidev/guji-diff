import 'package:diff_match_patch/diff_match_patch.dart';

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

/// 逐字校勘引擎
class VerbatimCollation {
  final DiffMatchPatch _dmp = DiffMatchPatch();

  /// 比较两个文本并返回差异列表
  List<CollationChange> compare(String text1, String text2) {
    final diffs = _dmp.diff(text1, text2);
    _dmp.diffCleanupSemantic(diffs);

    return diffs.map((d) {
      CollationType type;
      switch (d.operation) {
        case DIFF_INSERT:
          type = CollationType.insert;
          break;
        case DIFF_DELETE:
          type = CollationType.delete;
          break;
        case DIFF_EQUAL:
        default:
          type = CollationType.equal;
          break;
      }
      return CollationChange(type: type, text: d.text);
    }).toList();
  }

  /// 以 Unified Diff 格式输出（简化版）
  String toUnifiedDiff(String text1, String text2) {
    // final diffs = _dmp.diff(text1, text2);
    // _dmp.diffCleanupSemantic(diffs);
    // TODO: 实现自定义的 Unified Diff 输出格式
    return 'Not implemented yet';
  }
}
