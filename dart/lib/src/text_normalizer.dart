import 'package:diff_match_patch/diff_match_patch.dart';
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
    return normalizeWithMapping(
      text,
      ignorePunctuation: ignorePunctuation,
      ignoreTraditional: ignoreTraditional,
      ignoreVariants: ignoreVariants,
    ).normalized;
  }

  /// 根据配置对文本进行预处理，并返回位置映射信息
  /// 返回包含归一化文本和原始位置映射的结果
  static NormalizationResult normalizeWithMapping(
    String text, {
    required bool ignorePunctuation,
    required bool ignoreTraditional,
    required bool ignoreVariants,
  }) {
    String result = text;
    // 初始化: 每个字符映射到自己的位置
    List<OriginalPosition> positions = List.generate(
      text.length,
      (i) => OriginalPosition(i, i + 1),
    );

    // 1. 先处理异体字（在繁简转换之前）
    //    因为某些异体字 OpenCC 可能不认识
    if (ignoreVariants) {
      final variantResult = _applyVariantMappingWithPositions(
        result,
        positions,
      );
      result = variantResult.normalized;
      positions = variantResult.positions;
    }

    // 2. 处理繁简转换（使用 OpenCC）
    if (ignoreTraditional) {
      final tradResult = _convertTraditionalWithPositions(result, positions);
      result = tradResult.normalized;
      positions = tradResult.positions;
    }

    // 3. 处理标点符号
    if (ignorePunctuation) {
      final punctResult = _removePunctuationWithPositions(result, positions);
      result = punctResult.normalized;
      positions = punctResult.positions;
    }

    return NormalizationResult(result, positions);
  }

  /// 使用 OpenCC 进行繁简转换（带位置追踪）
  /// 如果 OpenCC 不可用，会抛出详细的错误信息
  /// OpenCC 保证1:1字符映射，所以位置数组保持不变
  static NormalizationResult _convertTraditionalWithPositions(
    String text,
    List<OriginalPosition> positions,
  ) {
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
      final simplified = _openccInstance!.traditionalToSimplified(text);

      // 如果长度完全一致，通常是 1:1 映射，直接返回（性能优化）
      if (simplified.length == text.length) {
        return NormalizationResult(simplified, positions);
      }

      // 长度不一致时，使用 diff 算法重新构建位置映射
      // 这能处理 1:N, N:1, N:M 的转换（如代理对、词组简化等）
      final dmp = DiffMatchPatch();
      final diffs = dmp.diff(text, simplified);
      final List<OriginalPosition> newPositions = [];

      int oldIdx = 0;
      for (int i = 0; i < diffs.length; i++) {
        final diff = diffs[i];
        final content = diff.text;
        final len = content.length;

        if (diff.operation == DIFF_EQUAL) {
          // 相同部分：直接复制原有的位置信息
          for (int k = 0; k < len; k++) {
            if (oldIdx + k < positions.length) {
              newPositions.add(positions[oldIdx + k]);
            }
          }
          oldIdx += len;
        } else if (diff.operation == DIFF_DELETE) {
          // 记录删除块，看后面是否有对应的 INSERT
          final delLen = len;
          final startIdx = oldIdx;
          oldIdx += delLen;

          // 检查下一个是否是 INSERT
          if (i + 1 < diffs.length && diffs[i + 1].operation == DIFF_INSERT) {
            final insDiff = diffs[i + 1];
            final insLen = insDiff.text.length;

            // 获取整个被替换区域的原始位置范围
            final startOrig = positions[startIdx].start;
            final endOrig = positions[startIdx + delLen - 1].end;

            // 分配给插入的每一个字符
            for (int k = 0; k < insLen; k++) {
              newPositions.add(OriginalPosition(startOrig, endOrig));
            }
            // 跳过已处理的 INSERT
            i++;
          }
        } else if (diff.operation == DIFF_INSERT) {
          // 纯插入（通常不会发生，除非 OpenCC 增加了内容）
          final startPos = oldIdx > 0 ? positions[oldIdx - 1].end : 0;
          final endPos = oldIdx < positions.length
              ? positions[oldIdx].start
              : (positions.isNotEmpty ? positions.last.end : 0);
          for (int k = 0; k < len; k++) {
            newPositions.add(OriginalPosition(startPos, endPos));
          }
        }
      }

      // 兜底方案：如果 diff 重构失败导致长度不匹配
      if (newPositions.length != simplified.length) {
        // ... 继续处理以防万一
        final finalPositions = List<OriginalPosition>.from(newPositions);
        while (finalPositions.length < simplified.length) {
          finalPositions.add(
            positions.isNotEmpty ? positions.last : OriginalPosition(0, 0),
          );
        }
        if (finalPositions.length > simplified.length) {
          return NormalizationResult(
            simplified,
            finalPositions.sublist(0, simplified.length),
          );
        }
        return NormalizationResult(simplified, finalPositions);
      }

      return NormalizationResult(simplified, newPositions);
    } on OpenCCNotAvailableException catch (e) {
      // 记录详细错误
      _logError('OpenCC conversion failed:\n$e');
      rethrow;
    } catch (e) {
      _logError('Unexpected error during conversion: $e');
      rethrow;
    }
  }

  /// 应用异体字映射（带位置追踪）
  /// 用于 OpenCC 不支持的古籍异体字
  /// 这是1:1字符替换，所以位置数组保持不变
  static NormalizationResult _applyVariantMappingWithPositions(
    String text,
    List<OriginalPosition> positions,
  ) {
    final buffer = StringBuffer();
    final newPositions = <OriginalPosition>[];

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final mapped = _variantCharMap[char] ?? char;

      buffer.write(mapped);
      // 位置映射保持不变：仍然是1:1映射
      newPositions.add(positions[i]);
    }

    return NormalizationResult(buffer.toString(), newPositions);
  }

  /// 删除标点符号（带位置追踪）
  /// 这会删除字符，所以需要缩减位置数组
  static NormalizationResult _removePunctuationWithPositions(
    String text,
    List<OriginalPosition> positions,
  ) {
    final buffer = StringBuffer();
    final newPositions = <OriginalPosition>[];

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      // 如果不是标点符号，保留该字符及其位置映射
      if (!_punctuationRegExp.hasMatch(char)) {
        buffer.write(char);
        // 防御性：如果 text 比 original 长（理论上 OpenCC 不应如此，但需防范越界）
        if (i < positions.length) {
          newPositions.add(positions[i]);
        } else if (newPositions.isNotEmpty) {
          // 如果超出长度，延续最后一个映射
          newPositions.add(newPositions.last);
        }
      }
      // 如果是标点符号，跳过（不添加到结果中）
    }

    return NormalizationResult(buffer.toString(), newPositions);
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

  /// 确保 OpenCC 准备就绪
  static Future<void> ensureReady() async {
    _openccInstance ??= createOpenCC();
    await _openccInstance!.untilReady();
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

/// 归一化结果，包含归一化文本和位置映射
class NormalizationResult {
  /// 归一化后的文本
  final String normalized;

  /// 位置映射数组，每个元素对应归一化文本中的一个字符
  final List<OriginalPosition> positions;

  NormalizationResult(this.normalized, this.positions);

  /// 根据归一化文本的位置范围，提取原文片段
  String extractOriginal(String originalText, int normStart, int normEnd) {
    // 防御性处理：如果 normEnd 超出映射数组长度，截断到末尾
    // 这可能发生在 OpenCC 转换不是严格 1:1 的情况下
    if (normEnd > positions.length) {
      normEnd = positions.length;
    }

    if (normStart < 0 ||
        normStart >= positions.length ||
        normEnd > positions.length ||
        normStart > normEnd) {
      // 如果 normStart 达到末尾，可能是归一化文本略长
      if (normStart >= positions.length && positions.isNotEmpty) {
        return '';
      }
      throw RangeError(
        'Invalid normalized position range: [$normStart, $normEnd). '
        'Positions length: ${positions.length}',
      );
    }

    // 空范围返回空字符串
    if (normStart == normEnd) {
      return '';
    }

    final startPos = positions[normStart].start;

    // 使用范围内最后一个字符的 end 位置
    // 这样可以正确排除中间被忽略的标点符号
    final endPos = positions[normEnd - 1].end;

    return originalText.substring(startPos, endPos);
  }
}

/// 原始文本位置信息
class OriginalPosition {
  /// 原文起始位置（包含）
  final int start;

  /// 原文结束位置（不包含）
  final int end;

  OriginalPosition(this.start, this.end);
}
