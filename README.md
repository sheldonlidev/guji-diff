# guji-diff

古籍文本校勘代码库 (Ancient Text Collation Library)。

给定两段或多段文字，`guji-diff` 能够高效输出它们之间的异同。该库专为古籍处理设计，支持繁简转换、异体字识别、标点忽略等高级功能，并提供多种语言实现。

## 🌟 核心特性

- **多粒度校勘**：支持从宏观结构到微观文字的全方位比较。
- **古籍专项优化**：
  - **繁简兼读**：可配置繁简体对应，即使字形不同也视为相同。
  - **异体/生僻字识别**：智能处理古籍中常见的异体字形。
  - **标点策略**：支持在比较时忽略标点符号，专注于文本本身的差异。
- **高性能算法**：底层基于 Google 的 `diff-match-patch` 算法，保证了处理速度与准确度。
- **多维度统计**：提供文本相似度计算，并自动识别并统计高频出现的改动模式。

## 🛠 校勘模式

本工具提供以下两种主要的校勘模式，以适应不同的应用场景：

### 1. 逐字校勘 (Verbatim Collation)
直接比较两段文本，精确找出每一个字符的增加、删除或替换。

**输出格式**：`Unified Diff`
- 经典的 Git/Linux 风格。
- 以行为单位，使用 `+` 表示新增，`-` 表示删除。

### 2. 结构性校勘 (Structural Collation)
针对已结构化（章节、段落、句子）的文本进行分层比较。它会先对齐章节，再对齐段落，最后在句子层面进行逐字校勘。

**输出格式**：`JSON Diff` (基于 RFC 6902 JSON Patch)
- 适用于程序自动化处理和数据库存储。
- 提供 `add`, `remove`, `replace` 等操作命令。

## 📊 统计与分析

除了基础的差异展示，`guji-diff` 还提供：
- **匹配度评分**：基于字符变动情况（增/删/改）计算文本相似度百分比。
- **模式识别**：自动统计高频出现的修改。例如，若文本中多处将 "A" 修正为 "B"，系统会将其作为典型规律进行汇总。

## 📺 示例展示

### Unified Diff 示例
```diff
--- original.txt
+++ corrected.txt
@@ -1,3 +1,3 @@
-大学之道在明明得
+大学之道在明明德
```

### JSON Diff 示例
```json
[
  { "op": "replace", "path": "/blocks/0/text", "value": "大学之道在明明德" }
]
```

## 🚀 快速上手 (Dart)

### 1. 添加依赖
将 `guji_diff` 添加到你的 `pubspec.yaml`:
```yaml
dependencies:
  guji_diff:
    path: ./dart # 目前作为本地 package 使用
```

### 2. 代码示例 (API)

#### 逐字校勘 (含古籍优化)
```dart
import 'package:guji_diff/guji_diff.dart';

void main() {
  final engine = VerbatimCollation();
  
  // 配置校勘选项
  final options = CollationOptions(
    ignorePunctuation: true,  // 忽略标点
    ignoreTraditional: true,  // 繁简等价
    ignoreVariants: true,     // 异体字等价
  );

  final text1 = '學而時習之，灋箇中。';
  final text2 = '学而时习之法个中';

  final changes = engine.compare(text1, text2, options: options);
  
  for (var change in changes) {
    print('${change.type}: ${change.text}');
  }
}
```

#### 结构化校勘 (JSON Patch)
```dart
import 'package:guji_diff/guji_diff.dart';

void main() {
  final doc1 = Document(chapters: [
    Chapter(title: '第一章', paragraphs: [
      Paragraph(id: 'p1', content: '原始内容'),
    ])
  ]);

  final doc2 = Document(chapters: [
    Chapter(title: '第一章', paragraphs: [
      Paragraph(id: 'p1', content: '修正内容'),
    ])
  ]);

  final engine = StructuralCollation();
  final diffs = engine.compareDocuments(doc1, doc2);
  
  // 转换为标准的 JSON Patch (RFC 6902)
  final patch = JsonPatchConverter.convert(diffs);
  print(patch);
}
```

### 3. 命令行工具 (CLI)
你可以直接在终端运行校勘命令：

#### 逐字比对 (字符串)
```bash
# 开启繁简等价和标点忽略
dart run dart/bin/guji_diff.dart "學而時習之" "学而时习之" --ignore-traditional --ignore-punctuation
```

#### 数据分析报告 (JSON)
通过 `--analyze` 参数生成统计报告：

```bash
dart run dart/bin/guji_diff.dart "大学之道在明明得" "大学之道在明明德" --analyze
```

**输出示例**:
```json
Statistical Analysis Report (JSON):
{
  "similarity": 0.875,
  "patterns": {
    "得->德": 1
  },
  "totalChanges": 1
}
```

#### 结构化比对 (JSON 文件)
你可以对比两个结构化的 JSON 文档模型：

```bash
dart run dart/bin/guji_diff.dart doc1.json doc2.json --structural
```

**输出示例 (JSON Patch)**:
```json
Structural Collation Results (JSON Patch):
[
  {
    "op": "replace",
    "path": "/chapters/0/title",
    "value": "第一章修正"
  },
  {
    "op": "replace",
    "path": "/chapters/0/paragraphs/0/content",
    "value": "这是修改后的内容"
  }
]
```

---
底层算法致谢：[google/diff-match-patch](https://github.com/google/diff-match-patch)