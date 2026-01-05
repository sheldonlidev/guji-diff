# Guji-Diff Web 部署指南

## 概述

`guji-diff` 现在支持平台自适应的 OpenCC 繁简转换：

| 平台 | OpenCC 实现 | 说明 |
|------|------------|------|
| **原生** (Windows/Mac/Linux/iOS/Android) | OpenCC FFI | 使用 C++ 原生库，需要 CMake 编译 |
| **Web** | OpenCC-JS | 使用 JavaScript 版本，无需编译 |

## 平台自适应机制

### 自动平台检测

库使用 Dart 的条件导出功能，在编译时自动选择正确的实现：

```dart
// lib/src/opencc/opencc.dart
export 'opencc_native.dart'           // 原生平台
  if (dart.library.html) 'opencc_web.dart';  // Web 平台
```

### 统一接口

无论在哪个平台，用户代码都是一样的：

```dart
import 'package:guji_diff/guji_diff.dart';

// 在所有平台上都这样使用
final result = TextNormalizer.normalize(
  '學而時習之',
  ignorePunctuation: false,
  ignoreTraditional: true,  // 自动使用平台对应的 OpenCC
  ignoreVariants: false,
);
```

## Web 部署步骤

### 1. 在 HTML 中引入 OpenCC-JS

编辑 `web/index.html`，在 `<head>` 部分添加：

```html
<!-- OpenCC-JS Library -->
<script src="https://cdn.jsdelivr.net/npm/opencc-js@1.0.5/dist/umd/full.js"></script>

<!-- OpenCC Bridge (Dart <-> JS 桥接) -->
<script src="opencc_bridge.js"></script>
```

### 2. 确保 opencc_bridge.js 存在

该文件已在 `dart/web/opencc_bridge.js`，内容如下：

```javascript
function checkOpenCCExists() {
  return typeof OpenCC !== 'undefined' && typeof OpenCC.Converter !== 'undefined';
}

function callOpenCCConvert(text, from, to) {
  const converter = OpenCC.Converter({ from: from, to: to });
  return converter(text);
}

window.checkOpenCCExists = checkOpenCCExists;
window.callOpenCCConvert = callOpenCCConvert;
```

### 3. 编译为 Web 应用

```bash
cd dart
flutter build web
```

### 4. 部署到 Web 服务器

将 `build/web` 目录的内容部署到任何静态 Web 服务器：

```bash
# 本地测试
flutter run -d chrome

# 或使用简单的 HTTP 服务器
cd build/web
python -m http.server 8000
# 访问 http://localhost:8000
```

## 文件结构

```
dart/
├── lib/
│   └── src/
│       ├── opencc/
│       │   ├── opencc.dart           # 条件导出入口
│       │   ├── opencc_interface.dart  # 平台抽象接口
│       │   ├── opencc_native.dart     # 原生平台实现 (FFI)
│       │   └── opencc_web.dart        # Web 平台实现 (JS)
│       └── text_normalizer.dart       # 使用 opencc
└── web/
    ├── index.html                     # 引入 OpenCC-JS
    └── opencc_bridge.js               # Dart <-> JS 桥接
```

## 使用示例

### 作为库被其他项目引用

当其他 Flutter 项目引用 `guji-diff` 时：

```yaml
# 其他项目的 pubspec.yaml
dependencies:
  guji_diff:
    path: ../guji-diff/dart  # 或使用 pub.dev 版本
```

**原生应用（自动使用 FFI）：**

```dart
import 'package:guji_diff/guji_diff.dart';

// 使用繁简转换
final collation = VerbatimCollation(
  '學而時習之',
  '学而时习之',
  options: CollationOptions(
    ignoreTraditional: true,  // 自动使用 OpenCC FFI
  ),
);
```

需要安装 CMake：
```bash
# Windows
choco install cmake

# macOS
brew install cmake

# Linux
sudo apt-get install cmake

# 然后
flutter pub get
```

**Web 应用（自动使用 OpenCC-JS）：**

1. 编辑 Web 应用的 `web/index.html`：

```html
<!DOCTYPE html>
<html>
<head>
  <!-- 其他 meta 标签 -->

  <!-- 添加 OpenCC-JS -->
  <script src="https://cdn.jsdelivr.net/npm/opencc-js@1.0.5/dist/umd/full.js"></script>

  <!-- 从 guji-diff 复制 opencc_bridge.js 到你的 web 目录 -->
  <script src="opencc_bridge.js"></script>
</head>
<body>
  <!-- 你的应用 -->
</body>
</html>
```

2. 从 `guji-diff/dart/web/opencc_bridge.js` 复制到你的项目的 `web/` 目录

3. 使用相同的 API：

```dart
import 'package:guji_diff/guji_diff.dart';

// Web 上会自动使用 OpenCC-JS，无需任何修改
final collation = VerbatimCollation(
  '學而時習之',
  '学而时习之',
  options: CollationOptions(
    ignoreTraditional: true,  // 自动使用 OpenCC-JS
  ),
);
```

## 诊断和调试

### 检查 OpenCC 状态

```dart
import 'package:guji_diff/guji_diff.dart';

// 检查当前平台
print('Platform: ${TextNormalizer.getPlatformName()}');
// Web: "Web (OpenCC-JS)"
// 原生: "Native (OpenCC FFI)"

// 检查 OpenCC 是否可用
final status = TextNormalizer.openccStatus;
if (status == OpenCCStatus.available) {
  print('OpenCC is ready');
} else {
  print('OpenCC is not available');
}
```

### Web 平台常见问题

**问题：OpenCC-JS 未加载**

检查浏览器控制台：
```javascript
// 在浏览器控制台执行
console.log(typeof OpenCC);  // 应该是 'object'
console.log(typeof checkOpenCCExists);  // 应该是 'function'
checkOpenCCExists();  // 应该返回 true
```

**解决方案：**
1. 确保 `index.html` 中正确引入了 OpenCC-JS
2. 确保 `opencc_bridge.js` 被加载
3. 检查网络请求，确保 CDN 可访问

**问题：转换不工作**

测试 OpenCC-JS：
```javascript
// 在浏览器控制台执行
const converter = OpenCC.Converter({ from: 'tw', to: 's' });
console.log(converter('學而時習之'));  // 应该输出: 学而时习之
```

## 性能对比

| 操作 | 原生 (FFI) | Web (JS) |
|------|-----------|----------|
| 初始化 | 快 (~1ms) | 中 (~10ms，需加载 JS) |
| 转换速度 | 很快 | 快 |
| 内存占用 | 低 | 中 |
| 包大小影响 | 需编译 (~2MB) | 无（使用 CDN） |

## CDN 选择

### 推荐 CDN

```html
<!-- jsDelivr (推荐，国内可访问) -->
<script src="https://cdn.jsdelivr.net/npm/opencc-js@1.0.5/dist/umd/full.js"></script>

<!-- unpkg (备选) -->
<script src="https://unpkg.com/opencc-js@1.0.5/dist/umd/full.js"></script>
```

### 自托管

如果需要完全离线或内网部署：

1. 下载 opencc-js：
```bash
npm install opencc-js
cp node_modules/opencc-js/dist/umd/full.js dart/web/opencc.js
```

2. 修改 `index.html`：
```html
<script src="opencc.js"></script>
```

## 总结

✅ **统一 API**：在所有平台使用相同的代码
✅ **自动适配**：编译时自动选择正确的实现
✅ **Web 友好**：使用 OpenCC-JS，无需编译
✅ **原生高效**：使用 OpenCC FFI，性能最优
✅ **简单部署**：只需在 HTML 中添加两行代码

你的库现在可以无缝支持 Web 和原生平台了！🎉
