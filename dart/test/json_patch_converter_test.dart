import 'package:flutter_test/flutter_test.dart';
import 'package:guji_diff/guji_diff.dart';

void main() {
  group('JsonPatchConverter Tests', () {
    test('Convert StructuralDiffItem to JSON Patch', () {
      final diffs = [
        StructuralDiffItem(
          op: StructuralOp.replace,
          path: '/chapters/0/title',
          oldValue: '旧章',
          newValue: '新章',
        ),
        StructuralDiffItem(
          op: StructuralOp.add,
          path: '/chapters/1',
          newValue: {'title': '第二章', 'paragraphs': []},
        ),
      ];

      final patch = JsonPatchConverter.convert(diffs);

      expect(patch.length, 2);
      expect(patch[0]['op'], 'replace');
      expect(patch[0]['path'], '/chapters/0/title');
      expect(patch[0]['value'], '新章');

      expect(patch[1]['op'], 'add');
      expect(patch[1]['path'], '/chapters/1');
      expect(patch[1]['value']['title'], '第二章');
    });
  });
}
