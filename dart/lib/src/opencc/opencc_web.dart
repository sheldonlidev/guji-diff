import 'dart:js_interop';

import 'opencc_interface.dart';

/// Web 平台的 OpenCC 实现
/// 使用 opencc-js 通过 JavaScript 互操作
class OpenCCWeb implements OpenCCInterface {
  bool _isInitialized = false;
  String? _lastError;

  @override
  bool isAvailable() {
    if (_isInitialized) return _lastError == null;

    try {
      // 检查 OpenCC JavaScript 库是否加载
      if (!_isOpenCCJSLoaded()) {
        _lastError = 'OpenCC-JS library not loaded in HTML';
        _isInitialized = true;
        return false;
      }

      _isInitialized = true;
      _lastError = null;
      return true;
    } catch (e) {
      _lastError = e.toString();
      _isInitialized = true;
      return false;
    }
  }

  @override
  String traditionalToSimplified(String text) {
    if (!isAvailable()) {
      throw OpenCCNotAvailableException(
        message: 'OpenCC-JS is not available',
        platform: 'Web',
        details: _lastError ??
            'Please include opencc-js in your web/index.html:\n'
                '<script src="https://cdn.jsdelivr.net/npm/opencc-js@1.0.5/dist/umd/full.js"></script>',
      );
    }

    try {
      return _convertText(text, 'tw', 's');
    } catch (e) {
      throw OpenCCNotAvailableException(
        message: 'OpenCC conversion failed',
        platform: 'Web',
        details: e.toString(),
      );
    }
  }

  @override
  String simplifiedToTraditional(String text) {
    if (!isAvailable()) {
      throw OpenCCNotAvailableException(
        message: 'OpenCC-JS is not available',
        platform: 'Web',
        details: _lastError ??
            'Please include opencc-js in your web/index.html',
      );
    }

    try {
      return _convertText(text, 's', 'tw');
    } catch (e) {
      throw OpenCCNotAvailableException(
        message: 'OpenCC conversion failed',
        platform: 'Web',
        details: e.toString(),
      );
    }
  }

  @override
  String getPlatformName() => 'Web (OpenCC-JS)';

  /// 检查 OpenCC JavaScript 库是否已加载
  bool _isOpenCCJSLoaded() {
    try {
      // 检查全局对象是否存在
      final hasOpenCC = _checkOpenCCExists();
      return hasOpenCC;
    } catch (e) {
      return false;
    }
  }

  /// 使用 OpenCC-JS 转换文本
  String _convertText(String text, String from, String to) {
    try {
      // 调用 JavaScript 函数进行转换
      final result = _callOpenCCConvert(text, from, to);
      return result;
    } catch (e) {
      throw Exception('OpenCC-JS conversion error: $e');
    }
  }
}

/// 检查 OpenCC 是否存在（通过 JS 互操作）
@JS('checkOpenCCExists')
external bool _checkOpenCCExists();

/// 调用 OpenCC 转换（通过 JS 互操作）
@JS('callOpenCCConvert')
external String _callOpenCCConvert(String text, String from, String to);

/// 创建 Web 平台的 OpenCC 实例
OpenCCInterface createOpenCC() => OpenCCWeb();
