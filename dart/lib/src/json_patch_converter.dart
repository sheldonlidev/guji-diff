import 'structural_collation.dart';

/// 将校勘差异转换为 RFC 6902 JSON Patch 格式
class JsonPatchConverter {
  /// 转换为 JSON 对象列表
  static List<Map<String, dynamic>> convert(List<StructuralDiffItem> diffs) {
    return diffs.map((d) {
      final patch = <String, dynamic>{'op': _opToString(d.op), 'path': d.path};

      switch (d.op) {
        case StructuralOp.add:
          patch['value'] = d.newValue;
          break;
        case StructuralOp.remove:
          // RFC 6902 remove 只有 op 和 path
          break;
        case StructuralOp.replace:
          patch['value'] = d.newValue;
          break;
        case StructuralOp.equal:
          break;
      }

      return patch;
    }).toList();
  }

  static String _opToString(StructuralOp op) {
    switch (op) {
      case StructuralOp.add:
        return 'add';
      case StructuralOp.remove:
        return 'remove';
      case StructuralOp.replace:
        return 'replace';
      case StructuralOp.equal:
        return 'test'; // 或者自定义
    }
  }
}
