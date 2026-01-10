## 0.2.0
- **修复 (Issue #4)**：优化了换行符对齐逻辑。现在，同时出现在对比文本两边的换行符会被正确对齐为“相等”（EQUAL）状态，而不是被分割到删除和插入中。
- **修复 (Issue #3)**：增强了 `TextNormalizer` 的鲁棒性。防止了当繁简转换导致字符串长度发生变化时，因位置映射计算越界而引发的程序崩溃。
- 新增了针对换行符对齐逻辑的单元测试。

## 0.1.2
- Improved `README.md` for better clarity.
- Updated `position-mapping-algorithm.md` to reflect latest implementation details.
- Code cleanup in `TextNormalizer`.
- Allow output both original text and compared text.

## 0.1.1

* Refactored collation feature tests for better coverage.
* Improved homepage UI with native Flutter widgets.
* Refined statistical analysis (`SimilarityScorer` & `ChangePatternAnalyzer`).
* Fixed various lint warnings and code quality issues.
* Updated documentation and README for better clarity.

## 0.1.0

* Initial release
* Verbatim collation with diff-match-patch
* Structural collation with JSON Patch output
* Statistical analysis and pattern recognition
* Platform-adaptive OpenCC integration:
  - Native platforms: OpenCC FFI
  - Web platform: OpenCC-JS
* Support for traditional/simplified Chinese conversion
* Variant character mapping
* Punctuation handling options
