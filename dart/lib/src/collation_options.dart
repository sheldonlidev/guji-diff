/// 校勘配置项
class CollationOptions {
  /// 是否忽略标点符号
  final bool ignorePunctuation;

  /// 是否忽略繁简体差异（自动归一化）
  final bool ignoreTraditional;

  /// 是否忽略异体字差异
  final bool ignoreVariants;

  const CollationOptions({
    this.ignorePunctuation = false,
    this.ignoreTraditional = false,
    this.ignoreVariants = false,
  });

  /// 默认配置
  static const defaultOptions = CollationOptions();
}
