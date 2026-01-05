import 'models.dart';
import 'verbatim_collation.dart';
import 'collation_options.dart';

/// 表示结构化校勘中的操作类型
enum StructuralOp { add, remove, equal, replace }

/// 表示结构化差异的一个条目
class StructuralDiffItem {
  final StructuralOp op;
  final String path;
  final dynamic oldValue;
  final dynamic newValue;
  final List<CollationChange>? textDiff;

  StructuralDiffItem({
    required this.op,
    required this.path,
    this.oldValue,
    this.newValue,
    this.textDiff,
  });
}

/// 结构化校勘引擎
class StructuralCollation {
  final VerbatimCollation _verbatim = VerbatimCollation();

  /// 比较两个文档
  List<StructuralDiffItem> compareDocuments(
    Document doc1,
    Document doc2, {
    CollationOptions options = CollationOptions.defaultOptions,
  }) {
    final results = <StructuralDiffItem>[];

    // 简单的对齐算法：基于索引或标题/ID（目前先按索引对齐，后续可增强）
    final maxChapters = doc1.chapters.length > doc2.chapters.length
        ? doc1.chapters.length
        : doc2.chapters.length;

    for (var i = 0; i < maxChapters; i++) {
      final path = '/chapters/$i';

      if (i >= doc1.chapters.length) {
        // 新增章节
        results.add(
          StructuralDiffItem(
            op: StructuralOp.add,
            path: path,
            newValue: doc2.chapters[i].toJson(),
          ),
        );
        continue;
      }

      if (i >= doc2.chapters.length) {
        // 删除章节
        results.add(
          StructuralDiffItem(
            op: StructuralOp.remove,
            path: path,
            oldValue: doc1.chapters[i].toJson(),
          ),
        );
        continue;
      }

      // 对齐章节内容
      _compareChapters(
        doc1.chapters[i],
        doc2.chapters[i],
        path,
        results,
        options,
      );
    }

    return results;
  }

  void _compareChapters(
    Chapter c1,
    Chapter c2,
    String basePath,
    List<StructuralDiffItem> results,
    CollationOptions options,
  ) {
    // 比较标题
    if (c1.title != c2.title) {
      results.add(
        StructuralDiffItem(
          op: StructuralOp.replace,
          path: '$basePath/title',
          oldValue: c1.title,
          newValue: c2.title,
        ),
      );
    }

    // 比较段落
    final maxParas = c1.paragraphs.length > c2.paragraphs.length
        ? c1.paragraphs.length
        : c2.paragraphs.length;

    for (var j = 0; j < maxParas; j++) {
      final paraPath = '$basePath/paragraphs/$j';

      if (j >= c1.paragraphs.length) {
        results.add(
          StructuralDiffItem(
            op: StructuralOp.add,
            path: paraPath,
            newValue: c2.paragraphs[j].toJson(),
          ),
        );
        continue;
      }

      if (j >= c2.paragraphs.length) {
        results.add(
          StructuralDiffItem(
            op: StructuralOp.remove,
            path: paraPath,
            oldValue: c1.paragraphs[j].toJson(),
          ),
        );
        continue;
      }

      final p1 = c1.paragraphs[j];
      final p2 = c2.paragraphs[j];

      if (p1.content != p2.content) {
        final textDiff = _verbatim.compare(
          p1.content,
          p2.content,
          options: options,
        );

        // 如果文本完全一致（可能是因为归一化策略），则不计为差异
        if (textDiff.length == 1 && textDiff[0].type == CollationType.equal) {
          continue;
        }

        results.add(
          StructuralDiffItem(
            op: StructuralOp.replace,
            path: '$paraPath/content',
            oldValue: p1.content,
            newValue: p2.content,
            textDiff: textDiff,
          ),
        );
      }
    }
  }
}
