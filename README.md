# Guji-Diff

[![pub package](https://img.shields.io/pub/v/guji_diff.svg)](https://pub.dev/packages/guji_diff)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

古籍文本校勘代码库 (Ancient Text Collation Library)

给定两段或多段文字，`guji-diff` 能够高效输出它们之间的异同。该库专为古籍处理设计，支持繁简转换、异体字识别、标点忽略等高级功能，并**支持多平台部署**（原生应用和 Web）。

## 🌟 核心特性

- **多粒度校勘**：支持从宏观结构到微观文字的全方位比较
- **古籍专项优化**：
  - **繁简兼读**：可配置繁简体对应，即使字形不同也视为相同
  - **异体/生僻字识别**：智能处理古籍中常见的异体字形
  - **标点策略**：支持在比较时忽略标点符号，专注于文本本身的差异
- **平台自适应**：原生应用使用 OpenCC FFI，Web 应用自动使用 OpenCC-JS
- **高性能算法**：底层基于 Google 的 `diff-match-patch` 算法
- **多维度统计**：提供文本相似度计算，并自动识别并统计高频出现的改动模式

## 📦 平台支持

| 平台 | 繁简转换 | 说明 |
|------|---------|------|
| **Windows/Mac/Linux** | ✅ OpenCC FFI | 需要安装 CMake |
| **iOS/Android** | ✅ OpenCC FFI | 自动编译 |
| **Web** | ✅ OpenCC-JS | 需配置 HTML |

## 🛠 校勘模式

### 1. 逐字校勘 (Verbatim Collation)
直接比较两段文本，精确找出每一个字符的增加、删除或替换。

**输出格式**：`Unified Diff`
- 经典的 Git/Linux 风格
- 以行为单位，使用 `+` 表示新增，`-` 表示删除

### 2. 结构性校勘 (Structural Collation)
针对已结构化（章节、段落、句子）的文本进行分层比较。

**输出格式**：`JSON Diff` (基于 RFC 6902 JSON Patch)
- 适用于程序自动化处理和数据库存储
- 提供 `add`, `remove`, `replace` 等操作命令

## 📊 统计与分析

- **匹配度评分**：基于字符变动情况计算文本相似度百分比
- **模式识别**：自动统计高频出现的修改

---

## 🚀 快速开始

### 安装

**从 pub.dev 安装（推荐）**：

在你的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  guji_diff: ^0.1.0
```

然后运行：

```bash
flutter pub get
```

**其他安装方式**：

```yaml
dependencies:
  # 从 Git 仓库安装
  guji_diff:
    git:
      url: https://github.com/sheldonlidev/guji-diff.git
      path: dart
      ref: main

  # 本地开发
  guji_diff:
    path: ../guji-diff/dart
```

---

## 💻 原生平台使用（Windows/Mac/Linux/iOS/Android）

### 前置要求

原生平台需要 **CMake** 来编译 OpenCC 库：

```bash
# Windows (使用 Chocolatey)
choco install cmake

# macOS (使用 Homebrew)
brew install cmake

# Linux (Ubuntu/Debian)
sudo apt-get install cmake

# 验证安装
cmake --version
```

### 代码示例

```dart
import 'package:guji_diff/guji_diff.dart';

void main() {
  // 逐字校勘（自动使用 OpenCC FFI）
  final collation = VerbatimCollation(
    '學而時習之，不亦說乎',
    '学而时习之，不亦说乎',
    options: CollationOptions(
      ignorePunctuation: true,   // 忽略标点
      ignoreTraditional: true,   // 繁简等价（使用 OpenCC FFI）
      ignoreVariants: true,      // 异体字映射
    ),
  );

  final diffs = collation.getDiffs();
  print('相似度: ${collation.getSimilarity()}');
}
```

### 运行应用

```bash
# 桌面应用
flutter run -d windows  # 或 macos/linux

# 移动应用
flutter run -d ios      # 或 android
```

---

## 🌐 Web 平台使用

### 配置 HTML

在 `web/index.html` 的 `<head>` 部分添加 OpenCC-JS：

```html
<script src="https://cdn.jsdelivr.net/npm/opencc-js@1.0.5/dist/umd/full.js"></script>
```

就这么简单！代码与原生平台完全一样：

```dart
import 'package:guji_diff/guji_diff.dart';

final collation = VerbatimCollation(
  '學而時習之',
  '学而时习之',
  options: CollationOptions(ignoreTraditional: true),  // 自动使用 OpenCC-JS
);
```

### 编译运行

```bash
flutter run -d chrome      # 开发
flutter build web          # 生产构建
```

---

## 📖 API 使用示例

### 示例 1: 逐字校勘（繁简等价）

```dart
import 'package:guji_diff/guji_diff.dart';

void main() {
  final engine = VerbatimCollation(
    '學而時習之，不亦說乎？',
    '学而时习之，不亦说乎？',
    options: CollationOptions(
      ignorePunctuation: true,   // 忽略标点
      ignoreTraditional: true,   // 繁简等价
      ignoreVariants: false,
    ),
  );

  // 获取差异列表
  final diffs = engine.getDiffs();
  for (var diff in diffs) {
    print('${diff.operation}: ${diff.text}');
  }

  // 计算相似度
  print('相似度: ${engine.getSimilarity()}');
}
```

### 示例 2: 异体字处理

```dart
final engine = VerbatimCollation(
  '箇中之道',  // 使用异体字 "箇"
  '个中之道',  // 标准字 "个"
  options: CollationOptions(
    ignoreVariants: true,  // 异体字等价
  ),
);

print('匹配: ${engine.getSimilarity() == 1.0}');  // true
```

### 示例 3: 结构化校勘

```dart
final doc1 = Document(chapters: [
  Chapter(title: '第一章', paragraphs: [
    Paragraph(id: 'p1', content: '大学之道，在明明得。'),
  ])
]);

final doc2 = Document(chapters: [
  Chapter(title: '第一章', paragraphs: [
    Paragraph(id: 'p1', content: '大学之道，在明明德。'),
  ])
]);

final engine = StructuralCollation();
final diffs = engine.compareDocuments(doc1, doc2);

// 转换为 JSON Patch (RFC 6902)
final patch = JsonPatchConverter.convert(diffs);
print(patch);
// 输出: [{"op":"replace","path":"/chapters/0/paragraphs/0/content","value":"大学之道，在明明德。"}]
```

### 示例 4: 统计分析

```dart
final analysis = StatisticalAnalysis.analyze('原文', '修订版', options);

print('相似度: ${analysis.similarity}');
print('总变更数: ${analysis.totalChanges}');
print('模式统计: ${analysis.patterns}');
// 输出: {得->德: 1}
```

---

## 🔧 命令行工具

### 安装

```bash
cd dart
dart pub get
```

### 使用示例

#### 1. 逐字比对

```bash
# 基础比对
dart run bin/guji_diff.dart "大学之道" "大学之门"

# 繁简等价
dart run bin/guji_diff.dart "學而時習之" "学而时习之" --ignore-traditional

# 忽略标点
dart run bin/guji_diff.dart "学习，思考。" "学习思考" --ignore-punctuation
```

#### 2. 统计分析

```bash
dart run bin/guji_diff.dart "大学之道在明明得" "大学之道在明明德" --analyze
```

输出：
```json
{
  "similarity": 0.875,
  "patterns": {
    "得->德": 1
  },
  "totalChanges": 1
}
```

#### 3. 结构化比对

```bash
dart run bin/guji_diff.dart doc1.json doc2.json --structural
```


### 版本历史

#### 0.1.0 (2026-01-05)
- ✅ 初始发布
- ✅ 逐字校勘功能
- ✅ 结构化校勘功能
- ✅ 统计分析和模式识别
- ✅ 平台自适应 OpenCC 集成（原生 FFI + Web JS）
- ✅ 繁简转换支持
- ✅ 异体字映射
- ✅ 标点处理选项

---

## 📚 相关文档

- [WEB_DEPLOYMENT_GUIDE.md](WEB_DEPLOYMENT_GUIDE.md) - Web 部署详细指南
- [PUBLISHING_GUIDE.md](PUBLISHING_GUIDE.md) - pub.dev 发布指南
- [progress/platform_adaptive_opencc.md](progress/platform_adaptive_opencc.md) - 平台自适应技术实现
- [progress/task_list.md](progress/task_list.md) - 项目开发进度

---

## 🙏 致谢

- 底层算法：[google/diff-match-patch](https://github.com/google/diff-match-patch)
- 繁简转换（原生）：[opencc-dart](https://github.com/lindeer/opencc-dart)
- 繁简转换（Web）：[opencc-js](https://github.com/nk2028/opencc-js)