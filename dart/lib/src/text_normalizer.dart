import 'package:opencc/opencc.dart';

/// 文字归一化处理工具
class TextNormalizer {
  /// 常见的中文标点符号正则
  static final RegExp _punctuationRegExp = RegExp(
    r'[\u3000-\u303F\uFF00-\uFFEF\u2000-\u206F\u2E00-\u2E7F!"#$%&'
    "'"
    r'()*+,\-./:;<=>?@\[\\\]^_`{|}~]',
  );

  /// 简单的异体字映射表
  /// 在 OpenCC 不可用或作为补充时使用
  static const Map<String, String> _variantMap = {
    '箇': '个',
    '盃': '杯',
    '灋': '法',
    '羣': '群',
    '學': '学',
    '時': '时',
    '習': '习',
  };

  static bool? _isOpenCCAvailable;

  /// 根据配置对文本进行预处理
  /// 返回处理后的文本
  static String normalize(
    String text, {
    required bool ignorePunctuation,
    required bool ignoreTraditional,
    required bool ignoreVariants,
  }) {
    String result = text;

    // 如果启用了异体字忽略，或者启用了繁简忽略但 OpenCC 不可用，则使用手动映射表
    final useFallbackMap =
        ignoreVariants || (ignoreTraditional && !(_checkOpenCC()));

    if (useFallbackMap) {
      _variantMap.forEach((variant, standard) {
        result = result.replaceAll(variant, standard);
      });
    }

    if (ignoreTraditional && _checkOpenCC()) {
      try {
        final converter = ZhConverter('t2s');
        result = converter.convert(result);
      } catch (e) {
        _isOpenCCAvailable = false;
        // 重新执行一次 fallback (虽然逻辑上上面已经处理了部分，但为了安全)
        _variantMap.forEach((variant, standard) {
          result = result.replaceAll(variant, standard);
        });
      }
    }

    if (ignorePunctuation) {
      result = result.replaceAll(_punctuationRegExp, '');
    }

    return result;
  }

  static bool _checkOpenCC() {
    if (_isOpenCCAvailable != null) return _isOpenCCAvailable!;
    try {
      // 尝试初始化一个最小的对象来检测原生库是否可用
      // 注意：有的 package 可能在构造时不报错，但在调用 convert 时报错
      ZhConverter('t2s');
      _isOpenCCAvailable = true;
    } catch (e) {
      _isOpenCCAvailable = false;
      print(
        '[GujiDiff] Warning: OpenCC native library not found. Falling back to simple normalization.',
      );
    }
    return _isOpenCCAvailable!;
  }
}
