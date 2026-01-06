/// OpenCC 平台抽象接口
/// 定义繁简转换的统一接口，由不同平台实现
abstract class OpenCCInterface {
  /// 创建平台特定的 OpenCC 实例
  /// 在 Web 上返回 JS 版本，在原生平台返回 FFI 版本
  factory OpenCCInterface() {
    // 条件导入会在编译时自动选择正确的实现
    return createOpenCC();
  }

  /// 检查 OpenCC 是否可用
  bool isAvailable();

  /// 繁体转简体
  ///
  /// [text] 要转换的文本
  ///
  /// 返回转换后的简体文本
  /// 如果 OpenCC 不可用，抛出 [OpenCCNotAvailableException]
  String traditionalToSimplified(String text);

  /// 简体转繁体
  ///
  /// [text] 要转换的文本
  ///
  /// 返回转换后的繁体文本
  /// 如果 OpenCC 不可用，抛出 [OpenCCNotAvailableException]
  String simplifiedToTraditional(String text);

  /// 获取当前平台名称（用于诊断）
  String getPlatformName();

  /// 等待 OpenCC 准备就绪
  /// 在 Web 上等待脚本加载，在原生平台上立即完成
  Future<void> untilReady();
}

/// OpenCC 不可用异常
class OpenCCNotAvailableException implements Exception {
  final String message;
  final String platform;
  final String? details;

  OpenCCNotAvailableException({
    required this.message,
    required this.platform,
    this.details,
  });

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln('OpenCCNotAvailableException: $message')
      ..writeln('Platform: $platform');
    if (details != null) {
      buffer.writeln('Details: $details');
    }
    return buffer.toString();
  }
}

/// 由平台特定的实现文件提供此函数
/// 在编译时会自动链接到正确的实现
///
/// 这个函数通过条件导出在不同平台上有不同的实现：
/// - Web: opencc_web.dart
/// - Native: opencc_native.dart
OpenCCInterface createOpenCC() {
  throw UnimplementedError(
    'createOpenCC() must be implemented by platform-specific code',
  );
}
