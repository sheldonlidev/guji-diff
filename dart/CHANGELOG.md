## 0.2.0
- **Fix (Issue #4)**: Improved newline alignment. Newlines present in both texts are now correctly aligned as EQUAL anchors.
- **Fix (Issue #3)**: Added robustness to `TextNormalizer` to prevent crashes when traditional/simplified conversion alters string length.
- Added unit tests for newline alignment logic.

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
