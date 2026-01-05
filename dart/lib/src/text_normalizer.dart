import 'opencc/opencc.dart';

/// 文字归一化处理工具
class TextNormalizer {
  /// 常见的中文标点符号正则
  static final RegExp _punctuationRegExp = RegExp(
    r'[\u3000-\u303F\uFF00-\uFFEF\u2000-\u206F\u2E00-\u2E7F!"#$%&'
    "'"
    r'()*+,\-./:;<=>?@\[\\\]^_`{|}~]',
  );

  /// 异体字映射表
  /// 用于 OpenCC 不支持的古籍异体字
  /// 这些字符即使在 OpenCC 中也可能没有对应的转换
  static const Map<String, String> _variantCharMap = {
    '箇': '个',
    // 可以继续添加更多古籍异体字
  };

  /// 平台自适应的 OpenCC 实例
  /// Web 平台使用 OpenCC-JS，原生平台使用 OpenCC FFI
  static OpenCCInterface? _openccInstance;

  /// 根据配置对文本进行预处理
  /// 返回处理后的文本
  static String normalize(
    String text, {
    required bool ignorePunctuation,
    required bool ignoreTraditional,
    required bool ignoreVariants,
  }) {
    String result = text;

    // 1. 先处理异体字（在繁简转换之前）
    //    因为某些异体字 OpenCC 可能不认识
    if (ignoreVariants) {
      result = _applyVariantMapping(result);
    }

    // 2. 处理繁简转换（使用 OpenCC）
    if (ignoreTraditional) {
      result = _convertTraditionalToSimplified(result);
    }

    // 3. 处理标点符号
    if (ignorePunctuation) {
      result = result.replaceAll(_punctuationRegExp, '');
    }

    return result;
  }

  /// 使用 OpenCC 进行繁简转换
  /// 如果 OpenCC 不可用，会抛出详细的错误信息
  static String _convertTraditionalToSimplified(String text) {
    // 懒加载 OpenCC 实例
    _openccInstance ??= createOpenCC();

    // 检查 OpenCC 是否可用
    if (!_openccInstance!.isAvailable()) {
      throw StateError(
        'OpenCC is not available on this platform. '
        'Platform: ${_openccInstance!.getPlatformName()}\n'
        'See TextNormalizer logs for details.',
      );
    }

    try {
      return _openccInstance!.traditionalToSimplified(text);
    } on OpenCCNotAvailableException catch (e) {
      // 记录详细错误
      _logError('OpenCC conversion failed:\n$e');
      rethrow;
    } catch (e) {
      _logError('Unexpected error during conversion: $e');
      rethrow;
    }
  }

  /// 应用异体字映射
  /// 用于 OpenCC 不支持的古籍异体字
  static String _applyVariantMapping(String text) {
    String result = text;
    _variantCharMap.forEach((variant, standard) {
      result = result.replaceAll(variant, standard);
    });
    return result;
  }

  /// 记录错误日志
  static void _logError(String message) {
    // ignore: avoid_print
    print('[GujiDiff] ERROR: $message');
  }

  /// 重置 OpenCC 实例（用于测试）
  static void resetOpenCCStatus() {
    _openccInstance = null;
  }

  /// 获取当前 OpenCC 状态（用于诊断）
  static OpenCCStatus? get openccStatus {
    _openccInstance ??= createOpenCC();
    return _openccInstance!.isAvailable()
        ? OpenCCStatus.available
        : OpenCCStatus.unavailable;
  }

  /// 获取平台信息（用于诊断）
  static String getPlatformName() {
    _openccInstance ??= createOpenCC();
    return _openccInstance!.getPlatformName();
  }
}

/// OpenCC 可用性状态枚举
enum OpenCCStatus {
  /// OpenCC 可用
  available,

  /// OpenCC 不可用
  unavailable,
}
