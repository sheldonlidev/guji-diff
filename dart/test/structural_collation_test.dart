import 'package:flutter_test/flutter_test.dart';
import 'package:guji_diff/guji_diff.dart';

void main() {
  group('StructuralCollation Tests', () {
    final engine = StructuralCollation();

    test('Simple Chapter/Paragraph replacement', () {
      final doc1 = Document(
        chapters: [
          Chapter(
            title: '第一章',
            paragraphs: [Paragraph(id: 'p1', content: '内容1')],
          ),
        ],
      );

      final doc2 = Document(
        chapters: [
          Chapter(
            title: '第一章修正',
            paragraphs: [Paragraph(id: 'p1', content: '内容1修改')],
          ),
        ],
      );

      final diffs = engine.compareDocuments(doc1, doc2);

      expect(
        diffs.any(
          (d) => d.op == StructuralOp.replace && d.path == '/chapters/0/title',
        ),
        isTrue,
      );
      expect(
        diffs.any(
          (d) =>
              d.op == StructuralOp.replace &&
              d.path == '/chapters/0/paragraphs/0/content',
        ),
        isTrue,
      );
    });

    test('Adding and removing chapters', () {
      final doc1 = Document(
        chapters: [Chapter(title: '旧章', paragraphs: [])],
      );

      final doc2 = Document(
        chapters: [
          Chapter(title: '新章', paragraphs: []),
          Chapter(title: '第二章', paragraphs: []),
        ],
      );

      final diffs = engine.compareDocuments(doc1, doc2);

      expect(
        diffs.any(
          (d) => d.op == StructuralOp.replace && d.path == '/chapters/0/title',
        ),
        isTrue,
      );
      expect(
        diffs.any((d) => d.op == StructuralOp.add && d.path == '/chapters/1'),
        isTrue,
      );
    });
  });
}
