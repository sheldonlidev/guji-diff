# 📖 Guji-Diff (古籍校勘引擎)

[![pub package](https://img.shields.io/pub/v/guji_diff.svg)](https://pub.dev/packages/guji_diff)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

专为古籍与现代文本校勘设计的 **智能对比引擎**。

Guji-Diff 不仅仅是一个 Diff 工具，它像一位精通古文的学者，能够智能识别异体字、繁简字，并提供从微观字形到宏观结构的立体化校勘结果。

---

## 核心功能

*   **智能校勘**：调用opencc繁简转换引擎，可选择忽略繁简差异。
*   **三维视图**：支持生成 **底本 (Base)**、**对校本 (Current)**、**合并 (Merged)** 三种视角的校勘结果。
*   **深度分析**：自动计算文本相似度，并统计高频修改模式（如 "得" -> "德" 出现了 10 次）。

##  快速开始

### 1. 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  guji_diff: ^0.1.0
```

### 2. 使用示例

```dart
import 'package:guji_diff/guji_diff.dart';

void main() {
  // 1. 创建校勘引擎
  // 示例文本：原文是繁体且有标点，新版本是简体且无标点
  final engine = VerbatimCollation(
    '學而時習之，不亦說乎？',
    '学而时习之不亦说乎',
    options: CollationOptions(
      ignorePunctuation: true, // 忽略标点差异
      ignoreTraditional: true, // 忽略繁简差异
    ),
  );

  // 2. 获取三种视角的校勘结果
  final result = engine.compareWithFullContext(
    engine.text1,
    engine.text2,
  );

  // 3. 打印合并视图 (Merged View) - 以底本为基础，展示增删
  print('--- 校勘结果 ---');
  for (final change in result.mergedView) {
    switch (change.type) {
      case CollationType.equal:
        print(change.text);         // 相同部分 (显示底本原文)
        break;
      case CollationType.insert:
        print('[+${change.text}]'); // 新增部分
        break;
      case CollationType.delete:
        print('[-${change.text}]'); // 删除部分
        break;
    }
  }
  
  // 4. 获取相似度评分
  print('\n相似度: ${(engine.getSimilarity() * 100).toStringAsFixed(1)}%');
}
```

## �️ 命令行工具

Guji-Diff 也可以作为命令行工具使用，快速分析文本差异。

```bash
# 激活工具 (如果在本地开发)
dart pub global activate -s path ./dart

# 运行比较 (自动忽略标点和繁简)
guji_diff "大学之道" "大學之道。" --analyze
```

**输出示例**：
```json
{
  "similarity": 1.0,
  "diffs": [
    {"op": "equal", "text": "大学之道"}
  ]
}
```

## 📚 更多文档

*   [Web 部署指南](WEB_DEPLOYMENT_GUIDE.md)
*   [核心算法原理](dart/position-mapping-algorithm.md)

---

Built with ❤️ by Guji Team.