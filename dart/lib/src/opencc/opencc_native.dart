import 'package:opencc/opencc.dart';

import 'opencc_interface.dart';

/// 原生平台的 OpenCC 实现
/// 使用 FFI 调用 OpenCC C++ 库
class OpenCCNative implements OpenCCInterface {
  ZhConverter? _t2sConverter;
  ZhConverter? _s2tConverter;
  bool _isInitialized = false;
  String? _lastError;

  @override
  bool isAvailable() {
    if (_isInitialized) return _lastError == null;

    try {
      // 尝试创建转换器来检测 OpenCC 是否可用
      _t2sConverter = ZhConverter('t2s');
      // 执行一次测试转换
      _t2sConverter!.convert('測試');

      _isInitialized = true;
      _lastError = null;
      return true;
    } catch (e) {
      _lastError = e.toString();
      _isInitialized = true;
      _t2sConverter = null;
      return false;
    }
  }

  @override
  String traditionalToSimplified(String text) {
    if (!isAvailable()) {
      throw OpenCCNotAvailableException(
        message: 'OpenCC native library is not available',
        platform: 'Native (FFI)',
        details: _lastError ??
            'OpenCC requires CMake to build native assets.\n'
                'Common causes:\n'
                '  1. CMake is not installed\n'
                '  2. CMake is not in system PATH\n'
                '  3. Make tools are not available\n'
                '  4. Native assets compilation failed\n'
                '\n'
                'To resolve:\n'
                '  1. Install CMake: https://cmake.org/download/\n'
                '  2. Add CMake to your system PATH\n'
                '  3. Run: flutter pub get\n'
                '  4. Rebuild your project\n'
                '\n'
                'For details: https://github.com/lindeer/opencc-dart/issues/1',
      );
    }

    try {
      _t2sConverter ??= ZhConverter('t2s');
      return _t2sConverter!.convert(text);
    } catch (e) {
      throw OpenCCNotAvailableException(
        message: 'OpenCC conversion failed',
        platform: 'Native (FFI)',
        details: e.toString(),
      );
    }
  }

  @override
  String simplifiedToTraditional(String text) {
    if (!isAvailable()) {
      throw OpenCCNotAvailableException(
        message: 'OpenCC native library is not available',
        platform: 'Native (FFI)',
        details: _lastError ?? 'Please install CMake and rebuild',
      );
    }

    try {
      _s2tConverter ??= ZhConverter('s2t');
      return _s2tConverter!.convert(text);
    } catch (e) {
      throw OpenCCNotAvailableException(
        message: 'OpenCC conversion failed',
        platform: 'Native (FFI)',
        details: e.toString(),
      );
    }
  }

  @override
  String getPlatformName() => 'Native (OpenCC FFI)';
}

/// 创建原生平台的 OpenCC 实例
OpenCCInterface createOpenCC() => OpenCCNative();
