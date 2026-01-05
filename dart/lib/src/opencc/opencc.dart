/// OpenCC 平台自适应接口
///
/// 此文件使用条件导出，在不同平台上自动选择正确的实现：
/// - Web 平台：使用 opencc-js (JavaScript 互操作)
/// - 原生平台：使用 opencc FFI (C++ 库)
///
/// 使用方式：
/// ```dart
/// import 'package:guji_diff/src/opencc/opencc.dart';
///
/// final opencc = OpenCCInterface();
/// if (opencc.isAvailable()) {
///   final result = opencc.traditionalToSimplified('學而時習之');
///   print(result); // 学而时习之
/// }
/// ```
library;

// 导出接口定义（隐藏 createOpenCC，因为它会被平台特定实现覆盖）
export 'opencc_interface.dart' hide createOpenCC;

// 条件导出：根据平台自动选择实现
// Web 平台 (dart:html 可用) -> opencc_web.dart
// 原生平台 (其他情况) -> opencc_native.dart
export 'opencc_native.dart' if (dart.library.html) 'opencc_web.dart';
