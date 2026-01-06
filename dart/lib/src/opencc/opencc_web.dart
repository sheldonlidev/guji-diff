import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'opencc_interface.dart';

/// Web 平台的 OpenCC 实现
/// 自动加载 OpenCC-JS 库并提供繁简转换功能
class OpenCCWeb implements OpenCCInterface {
  static const String _scriptUrl =
      'https://cdn.jsdelivr.net/npm/opencc-js@1.0.5/dist/umd/full.js';

  // 静态状态，确保多实例共享加载状态
  static bool __scriptInjected = false;
  static final Completer<void> _loadCompleter = Completer<void>();
  static String? _loadError;
  static final Map<String, JSFunction> _converterCache = {};

  static Future<void> get _ready => _loadCompleter.future;

  OpenCCWeb() {
    _ensureScriptInjected();
  }

  /// 确保 OpenCC-JS 脚本已注入
  static void _ensureScriptInjected() {
    if (__scriptInjected) return;
    __scriptInjected = true;

    // 如果全局对象已经存在（用户可能已经手动添加到了 index.html），直接标记为已加载
    if (_isOpenCCJSLoadedSync()) {
      if (!_loadCompleter.isCompleted) _loadCompleter.complete();
      return;
    }

    try {
      // 创建 script 标签
      final script =
          web.document.createElement('script') as web.HTMLScriptElement;
      script.src = _scriptUrl;
      script.async = true;

      // 监听加载完成
      script.onload = (web.Event e) {
        if (!_loadCompleter.isCompleted) _loadCompleter.complete();
      }.toJS;

      // 监听加载失败
      script.onerror = (web.Event e) {
        _loadError = 'Failed to load OpenCC-JS from $_scriptUrl';
        if (!_loadCompleter.isCompleted) {
          _loadCompleter.completeError(_loadError!);
        }
      }.toJS;

      // 插入到 head
      web.document.head!.appendChild(script);
    } catch (e) {
      _loadError = 'Error injecting script: $e';
      if (!_loadCompleter.isCompleted) {
        _loadCompleter.completeError(_loadError!);
      }
    }
  }

  @override
  bool isAvailable() => _isOpenCCJSLoadedSync();

  /// 同步检查 OpenCC JS 对象是否就绪
  static bool _isOpenCCJSLoadedSync() {
    try {
      return _openccGlobal != null;
    } catch (_) {
      return false;
    }
  }

  @override
  String traditionalToSimplified(String text) => _convert(text, 'tw', 's');

  @override
  String simplifiedToTraditional(String text) => _convert(text, 's', 'tw');

  /// 执行转换逻辑
  String _convert(String text, String from, String to) {
    if (!isAvailable()) {
      throw OpenCCNotAvailableException(
        message: 'OpenCC-JS is not available',
        platform: 'Web',
        details:
            _loadError ??
            'OpenCC-JS library is still loading. Please await untilReady() or try again.',
      );
    }

    try {
      final converter = _getConverter(from, to);
      // 调用 JS 函数进行转换
      final result = converter.callAsFunction(null, text.toJS) as JSString;
      return result.toDart;
    } catch (e) {
      throw OpenCCNotAvailableException(
        message: 'OpenCC conversion failed',
        platform: 'Web',
        details: 'Internal JS error: $e',
      );
    }
  }

  /// 获取或初始化转换器
  JSFunction _getConverter(String from, String to) {
    final key = '$from-$to';
    if (_converterCache.containsKey(key)) return _converterCache[key]!;

    final opencc = _openccGlobal;
    if (opencc == null) {
      throw Exception('OpenCC global object not found');
    }

    // 尝试不同的初始化方法以确保兼容性

    // 方法 1: OpenCC.Converter({ from, to }) - 现代接口
    final converterFn = _jsGet(opencc, 'Converter'.toJS);
    if (converterFn != null && converterFn.isA<JSFunction>()) {
      try {
        final options = JSObject();
        _jsSet(options, 'from'.toJS, from.toJS);
        _jsSet(options, 'to'.toJS, to.toJS);

        final converter = (converterFn as JSFunction).callAsFunction(
          opencc,
          options,
        );
        if (converter != null && converter.isA<JSFunction>()) {
          final fn = converter as JSFunction;
          _converterCache[key] = fn;
          return fn;
        }
      } catch (_) {}
    }

    // 方法 2: OpenCC.ConverterFactory({ locale: [from, to] }) - 某些 1.0.x 版本的接口
    final factoryFn = _jsGet(opencc, 'ConverterFactory'.toJS);
    if (factoryFn != null && factoryFn.isA<JSFunction>()) {
      try {
        final options = JSObject();
        final locale = JSArray();
        locale.add(from.toJS);
        locale.add(to.toJS);
        _jsSet(options, 'locale'.toJS, locale);

        final converter = (factoryFn as JSFunction).callAsFunction(
          opencc,
          options,
        );
        if (converter != null && converter.isA<JSFunction>()) {
          final fn = converter as JSFunction;
          _converterCache[key] = fn;
          return fn;
        }
      } catch (_) {}
    }

    // 自动回退逻辑
    if (from == 'tw' || from == 'hk') {
      try {
        return _getConverter('t', to);
      } catch (_) {}
    }
    if (to == 's') {
      try {
        return _getConverter(from, 'cn');
      } catch (_) {}
    }

    throw Exception('Could not initialize OpenCC converter for $from -> $to');
  }

  @override
  String getPlatformName() => 'Web (OpenCC-JS, Automated)';

  @override
  Future<void> untilReady() => _ready;
}

// JS 互操作辅助函数
@JS('window.OpenCC')
external JSObject? get _openccGlobal;

@JS('Reflect.get')
external JSAny? _jsGet(JSObject target, JSString property);

@JS('Reflect.set')
external bool _jsSet(JSObject target, JSString property, JSAny? value);

/// 创建 Web 平台的 OpenCC 实例
OpenCCInterface createOpenCC() => OpenCCWeb();
