# 文本归一化位置映射算法

## 1. 问题定义

### 1.1 背景

在古籍文本对比中，需要对文本进行归一化处理以忽略某些差异（如标点、异体字、繁简体），但同时又要在输出结果中保留原始文本的字符形式。

### 1.2 核心挑战

**问题**：归一化过程是有损转换，原始字符信息会丢失。

**示例**：
```
原始文本: "箇中學問，深不可測！"
归一化后: "个中学问深不可测"
```

经过归一化后，我们无法从 "个中学问深不可测" 还原出原文中的 "箇"、"學"、"問" 和标点符号。

### 1.3 解决方案

通过**位置映射追踪**，在归一化的每一步记录字符位置对应关系，使得我们可以根据归一化文本的位置反向查找原文片段。

## 2. 核心算法

### 2.1 数据结构

#### 2.1.1 原始位置记录

```dart
class OriginalPosition {
  final int start;  // 原文起始位置（包含）
  final int end;    // 原文结束位置（不包含）
}
```

**用途**：记录归一化文本中的每个字符对应原文的位置区间（半开区间 [start, end)）

#### 2.1.2 归一化结果

```dart
class NormalizationResult {
  final String normalized;              // 归一化后的文本
  final List<OriginalPosition> positions; // 位置映射数组

  // 根据归一化位置提取原文
  String extractOriginal(String originalText, int normStart, int normEnd);
}
```

**关键性质**：
- `positions.length == normalized.length`（一一对应）
- `positions[i]` 表示归一化文本第i个字符对应原文的位置

### 2.2 位置映射算法

#### 2.2.1 初始化

```
输入: 原始文本 text，长度为 n
输出: positions = [OriginalPosition(0,1), ..., OriginalPosition(n-1,n)]

每个字符初始映射到自己的位置
```

**示例**：
```
text = "箇中學"
positions = [
  OriginalPosition(0, 1),  // '箇' → [0,1)
  OriginalPosition(1, 2),  // '中' → [1,2)
  OriginalPosition(2, 3)   // '學' → [2,3)
]
```

#### 2.2.2 阶段1：异体字映射（1:1字符替换）

```
算法: _applyVariantMappingWithPositions(text, positions)
输入:
  - text: 当前文本
  - positions: 当前位置映射数组
输出:
  - normalized: 映射后的文本
  - newPositions: 更新后的位置数组

伪代码:
  newText = ""
  newPositions = []
  for i = 0 to text.length - 1:
    char = text[i]
    mapped = variantCharMap[char] ?? char  // 查表，不存在则保持原样
    newText.append(mapped)
    newPositions.append(positions[i])      // 位置映射保持不变

  return (newText, newPositions)
```

**关键特性**：
- 字符数量不变：`|newText| == |text|`
- 位置数组不变：`newPositions == positions`
- 只有字符内容改变，位置关系保持

**示例**：
```
输入:
  text = "箇中學"
  positions = [Pos(0,1), Pos(1,2), Pos(2,3)]

处理:
  '箇' → '个'  positions[0] = Pos(0,1) 保持
  '中' → '中'  positions[1] = Pos(1,2) 保持
  '學' → '學'  positions[2] = Pos(2,3) 保持

输出:
  normalized = "个中學"
  positions = [Pos(0,1), Pos(1,2), Pos(2,3)]  // 不变
```

#### 2.2.3 阶段2：繁简转换（1:1字符映射）

```
算法: _convertTraditionalWithPositions(text, positions)
输入:
  - text: 当前文本
  - positions: 当前位置映射数组
输出:
  - simplified: OpenCC转换后的文本
  - positions: 位置数组（不变）

伪代码:
  simplified = OpenCC.traditionalToSimplified(text)
  // OpenCC保证1:1映射，长度不变
  assert(simplified.length == text.length)
  return (simplified, positions)  // 位置数组原样返回
```

**关键特性**：
- 依赖OpenCC的1:1保证
- 位置数组完全不变
- 转换是确定性的

**示例**：
```
输入:
  text = "个中學"
  positions = [Pos(0,1), Pos(1,2), Pos(2,3)]

处理:
  '个' → '个'
  '中' → '中'
  '學' → '学'  (OpenCC转换)

输出:
  simplified = "个中学"
  positions = [Pos(0,1), Pos(1,2), Pos(2,3)]  // 完全不变
```

#### 2.2.4 阶段3：标点删除（字符缩减）

```
算法: _removePunctuationWithPositions(text, positions)
输入:
  - text: 当前文本
  - positions: 当前位置映射数组
输出:
  - noPunct: 删除标点后的文本
  - newPositions: 缩减后的位置数组

伪代码:
  noPunct = ""
  newPositions = []
  for i = 0 to text.length - 1:
    char = text[i]
    if not isPunctuation(char):  // 非标点字符
      noPunct.append(char)
      newPositions.append(positions[i])  // 保留该字符的位置映射
    // else: 标点字符被跳过，不添加到结果中

  return (noPunct, newPositions)
```

**关键特性**：
- 字符数量减少：`|noPunct| <= |text|`
- 位置数组缩减：只保留非标点字符的位置
- 删除的标点在原文中的位置信息会"跳过"

**示例**：
```
输入:
  text = "个中，学！"
  positions = [Pos(0,1), Pos(1,2), Pos(2,3), Pos(3,4), Pos(4,5)]

处理:
  '个' → 保留  newPositions.append(Pos(0,1))
  '中' → 保留  newPositions.append(Pos(1,2))
  '，' → 跳过  (标点)
  '学' → 保留  newPositions.append(Pos(3,4))
  '！' → 跳过  (标点)

输出:
  noPunct = "个中学"
  positions = [Pos(0,1), Pos(1,2), Pos(3,4)]  // 缩减了
```

### 2.3 完整示例

**原始文本**：`"箇中學問，深不可測！"`

#### 初始化
```
text = "箇中學問，深不可測！"
positions = [Pos(0,1), Pos(1,2), ..., Pos(10,11)]
```

#### 阶段1：异体字映射 (ignoreVariants=true)
```
'箇' → '个'
text = "个中學問，深不可測！"
positions = [Pos(0,1), Pos(1,2), ..., Pos(10,11)]  // 不变
```

#### 阶段2：繁简转换 (ignoreTraditional=true)
```
'學' → '学', '問' → '问', '測' → '测'
text = "个中学问，深不可测！"
positions = [Pos(0,1), Pos(1,2), ..., Pos(10,11)]  // 不变
```

#### 阶段3：标点删除 (ignorePunctuation=true)
```
删除 '，' (位置4) 和 '！' (位置10)
text = "个中学问深不可测"
positions = [Pos(0,1), Pos(1,2), Pos(2,3), Pos(3,4),
             Pos(5,6), Pos(6,7), Pos(7,8), Pos(8,9)]
```

#### 位置映射表
```
归一化[0] '个' → 原文[0:1] "箇"
归一化[1] '中' → 原文[1:2] "中"
归一化[2] '学' → 原文[2:3] "學"
归一化[3] '问' → 原文[3:4] "問"
归一化[4] '深' → 原文[5:6] "深"  ← 跳过了位置4的'，'
归一化[5] '不' → 原文[6:7] "不"
归一化[6] '可' → 原文[7:8] "可"
归一化[7] '测' → 原文[8:9] "測"  ← 位置10的'！'被删除
```

## 3. 原文提取算法

### 3.1 extractOriginal 方法

```
算法: extractOriginal(originalText, normStart, normEnd)
输入:
  - originalText: 原始文本字符串
  - normStart: 归一化文本起始位置（包含）
  - normEnd: 归一化文本结束位置（不包含）
输出:
  - 原文片段字符串

伪代码:
  if normStart == normEnd:
    return ""  // 空范围

  startPos = positions[normStart].start
  
  // 关键逻辑：使用下一个归一化字符的原文起始位置作为当前片段的结束位置
  // 这样可以自动包含两个归一化字符中间被跳过的原始内容（如标点）
  if normEnd < positions.length:
    endPos = positions[normEnd].start
  else:
    endPos = originalText.length  // 如果是最后，包含剩余所有内容

  return originalText.substring(startPos, endPos)
```

**关键点**：
- **向后贪婪匹配**：被跳过的内容（如标点）会通过 `positions[normEnd].start` 被包含在前一个片段中。
- 也就是：中间的标点归属于它**左边**的归一化字符片段。
- 最后一个片段会自动包含末尾所有剩余字符。

**示例**：
```
归一化文本: "个中学问深不可测"
原始文本: "箇中學問，深不可測！"
positions: [Pos(0,1), Pos(1,2), Pos(2,3), Pos(3,4),
            Pos(5,6), Pos(6,7), Pos(7,8), Pos(8,9)]
(标点 ',' 在位置4，'！' 在位置10)

extractOriginal("...", 0, 4)  // 提取 "个中学问"
  → startPos = positions[0].start = 0
  → endPos = positions[4].start = 5  // '深'的起始位置
  → originalText.substring(0, 5) = "箇中學問，"  ✓ 包含中间的逗号

extractOriginal("...", 3, 8)  // 提取 "问...测"
  → startPos = positions[3].start = 3
  → endPos = positions[8]不存在 → originalText.length = 11
  → originalText.substring(3, 11) = "問，深不可測！"  ✓ 包含尾部感叹号
```

## 4. Diff结果映射算法

### 4.1 问题描述

Diff算法在归一化文本上运行，产生的差异片段位置是基于归一化文本的。我们需要将这些位置映射回原文。

### 4.2 映射算法

```
算法: _mapDiffsToOriginal(diffs, originalText1, originalText2, norm1, norm2)
输入:
  - diffs: Diff算法产生的差异列表
  - originalText1, originalText2: 原始文本
  - norm1, norm2: 归一化结果（包含位置映射）
输出:
  - CollationChange列表（包含原文）

伪代码:
  result = []
  pos1 = 0  // 当前在归一化text1中的位置
  pos2 = 0  // 当前在归一化text2中的位置

  for each diff in diffs:
    length = diff.text.length

    switch diff.operation:
      case EQUAL:
        // 提取text1的原文片段
        originalText = norm1.extractOriginal(originalText1, pos1, pos1 + length)
        result.append(CollationChange(EQUAL, originalText))
        pos1 += length
        pos2 += length

      case DELETE:
        // 提取text1的原文片段
        originalText = norm1.extractOriginal(originalText1, pos1, pos1 + length)
        result.append(CollationChange(DELETE, originalText))
        pos1 += length

      case INSERT:
        // 提取text2的原文片段
        originalText = norm2.extractOriginal(originalText2, pos2, pos2 + length)
        result.append(CollationChange(INSERT, originalText))
        pos2 += length

  return result
```

**关键特性**：
- EQUAL段落使用text1的原文
- DELETE段落使用text1的原文
- INSERT段落使用text2的原文
- 位置游标分别追踪两个归一化文本

### 4.3 示例

```
Text1: "箇中學問"
Text2: "个中学问"
Options: {ignoreVariants: true, ignoreTraditional: true}

归一化:
  norm1.normalized = "个中学问"
  norm1.positions = [Pos(0,1), Pos(1,2), Pos(2,3), Pos(3,4)]

  norm2.normalized = "个中学问"
  norm2.positions = [Pos(0,1), Pos(1,2), Pos(2,3), Pos(3,4)]

Diff结果:
  [EQUAL("个中学问")]  // 完全相同

映射回原文:
  operation = EQUAL
  length = 4
  originalText = norm1.extractOriginal("箇中學問", 0, 4)
               = "箇中學問"  // 使用text1的原文

最终输出:
  [CollationChange(EQUAL, "箇中學問")]  ✓ 保留了原始字符形式

## 5. 完整上下文校勘 (Full Context Collation)

### 5.1 需求
除了简单的Diff列表，有时需要三种视图来展示完整的校勘结果：
1. **底本视图 (Text1 View)**：显示Text1的内容，标记哪些保留(EQUAL)、哪些被删除(DELETE)。
2. **对校本视图 (Text2 View)**：显示Text2的内容，标记哪些保留(EQUAL)、哪些是新增(INSERT)。
3. **合并视图 (Merged View)**：以底本(Text1)为基础，同时显示删除和新增的内容。

### 5.2 算法实现

```
算法: compareWithFullContext(text1, text2, options)
输入:
  - text1, text2: 原始文本
  - options: 归一化选项
输出:
  - FullCollationResult(text1View, text2View, mergedView)

伪代码:
  // 1. 获取归一化结果 (同上)
  norm1 = normalizeWithMapping(text1)
  norm2 = normalizeWithMapping(text2)

  // 2. 执行Diff (同上)
  diffs = diff(norm1, norm2)

  // 3. 生成视图
  text1View = []
  text2View = []
  mergedView = []

  pos1 = 0
  pos2 = 0

  for diff in diffs:
    length = diff.length

    switch diff.operation:
      case EQUAL:
        // 提取原文
        orig1 = norm1.extractOriginal(text1, pos1, pos1 + length)
        orig2 = norm2.extractOriginal(text2, pos2, pos2 + length)

        // Text1视图: 显示orig1 (EQUAL)
        text1View.add(EQUAL, orig1)
        // Text2视图: 显示orig2 (EQUAL)
        text2View.add(EQUAL, orig2)
        // Merged视图: 优先显示底本orig1 (EQUAL)
        mergedView.add(EQUAL, orig1)

        pos1 += length
        pos2 += length

      case DELETE:
        // 提取原文
        orig1 = norm1.extractOriginal(text1, pos1, pos1 + length)

        // Text1视图: 显示orig1 (DELETE)
        text1View.add(DELETE, orig1)
        // Text2视图: 空 (Text2没有这部分)
        // Merged视图: 显示orig1 (DELETE)
        mergedView.add(DELETE, orig1)

        pos1 += length

      case INSERT:
        // 提取原文
        orig2 = norm2.extractOriginal(text2, pos2, pos2 + length)

        // Text1视图: 空 (Text1没有这部分)
        // Text2视图: 显示orig2 (INSERT)
        text2View.add(INSERT, orig2)
        // Merged视图: 显示orig2 (INSERT)
        mergedView.add(INSERT, orig2)

        pos2 += length
```

### 5.3 视图特性
- **Text1 View**：完全还原Text1的字符序列（忽略Diff类型，连接所有片段即为OriginalText1）。
- **Text2 View**：完全还原Text2的字符序列。
- **Merged View**：
  - 包含Text1的所有字符（EQUAL + DELETE）。
  - 插入了Text2的新增字符（INSERT）。
  - 是最完整的差异展示视图。

## 6. 复杂度分析


### 6.1 空间复杂度

- **OriginalPosition 数组**：O(n)，n为文本长度
- **每个对象大小**：2个整数（start, end）约16字节
- **总内存**：n × 16字节
  - 1000字符 ≈ 16KB
  - 10000字符 ≈ 160KB

### 6.2 时间复杂度

| 操作 | 复杂度 | 说明 |
|------|--------|------|
| 初始化位置数组 | O(n) | 遍历一次生成 |
| 异体字映射 | O(n) | 逐字符处理 |
| 繁简转换 | O(n) | OpenCC内部优化 |
| 标点删除 | O(n) | 逐字符判断 |
| extractOriginal | O(m) | m为提取片段长度 |
| Diff算法 | O(n×m) | Myers算法 |
| 映射回原文 | O(k) | k为diff段落数 |

**总体复杂度**：O(n×m)，由Diff算法主导，位置追踪不增加渐进复杂度。


## 7. 算法正确性


### 7.1 不变量

在整个归一化过程中，以下不变量始终成立：

**不变量1**：`positions.length == normalized.length`
- 位置数组与归一化文本长度一致

**不变量2**：`positions[i]` 指向的原文片段，经归一化后得到 `normalized[i]`
- 映射关系的一致性

**不变量3**：对于任意 `i < j`，有 `positions[i].start <= positions[j].start`
- 位置单调性（可能有相等，当字符被删除时）

### 7.2 可逆性

虽然归一化本身不可逆（'箇'和'个'都映射到'个'），但**位置映射是可逆的**：

```
归一化位置 → 原文位置  (通过 positions 数组)
原文位置 → 归一化位置  (通过二分查找，O(log n))
```


## 8. 边界情况


### 8.1 空字符串

```
input = ""
positions = []
normalized = ""

extractOriginal("", 0, 0) → ""
```

### 8.2 纯标点

```
input = "，。！？"
经过标点删除:
  normalized = ""
  positions = []
```

### 8.3 连续标点

```
input = "學，。！問"
经过标点删除:
  normalized = "學問"
  positions = [Pos(0,1), Pos(4,5)]

extractOriginal(input, 0, 2)
  → substring(0, 5) = "學，。！問"  ✓ 包含所有中间字符
```

### 8.4 全部相同

```
text1 = text2 = "箇中學問"
归一化后相同
Diff: [EQUAL("个中学问")]
映射回原文: [EQUAL("箇中學問")]  // 显示text1的原文
```


## 9. 应用场景


### 9.1 古籍文本对比

保留原始字形，同时忽略版本差异：
- 繁简体差异
- 异体字差异
- 标点符号差异

### 9.2 OCR结果校对

识别结果可能有字形变化，但需要显示原扫描件中的字形。

### 9.3 多版本文献比对

不同版本可能使用不同字形规范，需要在显示时保留各自特征。


## 10. 扩展性


### 10.1 支持更多归一化操作

只要满足以下条件，可以添加新的归一化阶段：

1. **1:1字符映射**：直接复用位置数组
2. **字符删除**：过滤位置数组
3. **字符插入**：需要新的位置映射策略（当前不支持）

### 10.2 双向映射

当前只支持"归一化位置→原文位置"，可扩展为双向：

```dart
class BidirectionalMapping {
  Map<int, int> normalizedToOriginal;  // 归一化→原文
  Map<int, int> originalToNormalized;  // 原文→归一化
}
```

### 10.3 行列映射

扩展到2D位置（行号+列号），用于文档比对。


## 11. 参考实现

完整实现见：
- `dart/lib/src/text_normalizer.dart`
- `dart/lib/src/verbatim_collation.dart`
- `dart/test/text_normalizer_test.dart`
- `dart/test/verbatim_collation_test.dart`
