/**
 * OpenCC JavaScript Bridge
 * 为 Dart 提供 OpenCC-JS 的桥接函数
 */

/**
 * 检查 OpenCC 是否已加载
 * @returns {boolean} 如果 OpenCC 可用返回 true
 */
function checkOpenCCExists() {
  return typeof OpenCC !== 'undefined' && typeof OpenCC.Converter !== 'undefined';
}

/**
 * 使用 OpenCC 转换文本
 * @param {string} text - 要转换的文本
 * @param {string} from - 源语言 ('tw', 's', 't', 'hk', 'jp')
 * @param {string} to - 目标语言 ('s', 'tw', 't', 'hk', 'jp')
 * @returns {string} 转换后的文本
 */
function callOpenCCConvert(text, from, to) {
  try {
    if (!checkOpenCCExists()) {
      throw new Error('OpenCC is not loaded. Please include opencc-js in your HTML.');
    }

    // 创建转换器: new OpenCC.Converter({ from: 'tw', to: 's' })
    const converter = OpenCC.Converter({ from: from, to: to });

    // 执行转换
    const result = converter(text);

    return result;
  } catch (error) {
    console.error('OpenCC conversion error:', error);
    throw error;
  }
}

// 暴露到全局作用域，供 Dart 调用
window.checkOpenCCExists = checkOpenCCExists;
window.callOpenCCConvert = callOpenCCConvert;
