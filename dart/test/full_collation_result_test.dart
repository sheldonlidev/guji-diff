import 'package:flutter_test/flutter_test.dart';
import 'package:guji_diff/guji_diff.dart';

void main() {
  group('FullCollationResult - Three Views', () {
    final engine = VerbatimCollation();

    test('Simple case - text1 has delete, text2 has insert', () {
      final text1 = '箇中學問';  // text1: 异体字+繁体
      final text2 = '箇中道理';  // text2: 异体字+繁体
      final options = CollationOptions(
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: true,  // 忽略异体字
      );

      final result = engine.compareWithFullContext(text1, text2, options: options);

      // Text1视图应该包含：EQUAL('箇中') + DELETE('學問')
      expect(result.text1View.length, 2);
      expect(result.text1View[0].type, CollationType.equal);
      expect(result.text1View[0].text, '箇中');
      expect(result.text1View[1].type, CollationType.delete);
      expect(result.text1View[1].text, '學問');

      // Text2视图应该包含：EQUAL('箇中') + INSERT('道理')
      expect(result.text2View.length, 2);
      expect(result.text2View[0].type, CollationType.equal);
      expect(result.text2View[0].text, '箇中');
      expect(result.text2View[1].type, CollationType.insert);
      expect(result.text2View[1].text, '道理');

      // Merged视图应该包含：EQUAL('箇中') + DELETE('學問') + INSERT('道理')
      expect(result.mergedView.length, 3);
      expect(result.mergedView[0].type, CollationType.equal);
      expect(result.mergedView[0].text, '箇中');
      expect(result.mergedView[1].type, CollationType.delete);
      expect(result.mergedView[1].text, '學問');
      expect(result.mergedView[2].type, CollationType.insert);
      expect(result.mergedView[2].text, '道理');
    });

    test('Text1 and text2 preserve punctuation in their views', () {
      final text1 = '學，問！';  // text1有标点
      final text2 = '学问？';    // text2有不同标点
      final options = CollationOptions(
        ignorePunctuation: true,   // 忽略标点
        ignoreTraditional: true,   // 忽略繁简
        ignoreVariants: false,
      );

      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final result = engine.compareWithFullContext(text1, text2, options: options);

          // Text1视图：应该显示text1的原文（包括标点）
          expect(result.text1View.length, 1);
          expect(result.text1View[0].type, CollationType.equal);
          expect(result.text1View[0].text, '學，問！');  // 保留text1的标点

          // Text2视图：应该显示text2的原文（包括标点）
          expect(result.text2View.length, 1);
          expect(result.text2View[0].type, CollationType.equal);
          expect(result.text2View[0].text, '学问？');  // 保留text2的标点

          // Merged视图：使用text1的原文
          expect(result.mergedView.length, 1);
          expect(result.mergedView[0].type, CollationType.equal);
          expect(result.mergedView[0].text, '學，問！');  // Merged用text1
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('Text1 view shows traditional chars, text2 view shows simplified', () {
      final text1 = '箇中學問';  // text1: 异体字+繁体
      final text2 = '个中学问';  // text2: 简体
      final options = CollationOptions(
        ignorePunctuation: false,
        ignoreTraditional: true,   // 忽略繁简
        ignoreVariants: true,      // 忽略异体字
      );

      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final result = engine.compareWithFullContext(text1, text2, options: options);

          // Text1视图：保留text1的繁体字和异体字
          expect(result.text1View.length, 1);
          expect(result.text1View[0].type, CollationType.equal);
          expect(result.text1View[0].text, '箇中學問');  // 保留繁体和异体字

          // Text2视图：保留text2的简体字
          expect(result.text2View.length, 1);
          expect(result.text2View[0].type, CollationType.equal);
          expect(result.text2View[0].text, '个中学问');  // 保留简体

          // Merged视图：使用text1的原文
          expect(result.mergedView.length, 1);
          expect(result.mergedView[0].type, CollationType.equal);
          expect(result.mergedView[0].text, '箇中學問');
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('Complex case - multiple changes with all features preserved', () {
      final text1 = '箇中學，問！';  // text1: 异体字+繁体+标点
      final text2 = '个中学道理？';  // text2: 简体+不同标点
      final options = CollationOptions(
        ignorePunctuation: true,
        ignoreTraditional: true,
        ignoreVariants: true,
      );

      final status = TextNormalizer.openccStatus;
      if (status == OpenCCStatus.available || status == null) {
        try {
          final result = engine.compareWithFullContext(text1, text2, options: options);

          // Text1视图：EQUAL(箇中學，) + DELETE(問！)
          final text1Equal = result.text1View.where((c) => c.type == CollationType.equal).toList();
          final text1Delete = result.text1View.where((c) => c.type == CollationType.delete).toList();

          expect(text1Equal.isNotEmpty, isTrue);
          expect(text1Equal[0].text, contains('箇'));  // 保留异体字
          expect(text1Equal[0].text, contains('學'));  // 保留繁体字
          expect(text1Equal[0].text, contains('，'));  // 保留标点

          expect(text1Delete.isNotEmpty, isTrue);
          expect(text1Delete[0].text, contains('問'));  // 保留繁体字
          expect(text1Delete[0].text, contains('！'));  // 保留标点

          // Text2视图：EQUAL(个中学) + INSERT(道理？)
          final text2Equal = result.text2View.where((c) => c.type == CollationType.equal).toList();
          final text2Insert = result.text2View.where((c) => c.type == CollationType.insert).toList();

          expect(text2Equal.isNotEmpty, isTrue);
          expect(text2Equal[0].text, contains('个'));  // 保留简体
          expect(text2Equal[0].text, contains('学'));  // 保留简体

          expect(text2Insert.isNotEmpty, isTrue);
          expect(text2Insert[0].text, contains('道理'));  // 保留简体
          expect(text2Insert[0].text, contains('？'));   // 保留text2的标点

          // Merged视图：应该使用text1的EQUAL和DELETE，text2的INSERT
          final mergedEqual = result.mergedView.where((c) => c.type == CollationType.equal).toList();
          final mergedDelete = result.mergedView.where((c) => c.type == CollationType.delete).toList();
          final mergedInsert = result.mergedView.where((c) => c.type == CollationType.insert).toList();

          expect(mergedEqual.isNotEmpty, isTrue);
          expect(mergedEqual[0].text, contains('箇'));  // Merged用text1
          expect(mergedEqual[0].text, contains('學'));
          expect(mergedEqual[0].text, contains('，'));

          expect(mergedDelete.isNotEmpty, isTrue);
          expect(mergedInsert.isNotEmpty, isTrue);
          expect(mergedInsert[0].text, contains('？'));  // INSERT用text2的标点
        } catch (e) {
          expect(e, isA<StateError>());
        }
      }
    });

    test('Empty strings', () {
      final result = engine.compareWithFullContext('', '', options: CollationOptions.defaultOptions);

      // 空字符串的diff结果为空列表（没有任何diff操作）
      expect(result.text1View, isEmpty);
      expect(result.text2View, isEmpty);
      expect(result.mergedView, isEmpty);
    });

    test('Text1 only delete - text2View has no delete segments', () {
      final text1 = '箇中學問';
      final text2 = '箇中';
      final options = CollationOptions(
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: true,
      );

      final result = engine.compareWithFullContext(text1, text2, options: options);

      // Text1视图：EQUAL + DELETE
      expect(result.text1View.length, 2);
      expect(result.text1View[0].type, CollationType.equal);
      expect(result.text1View[1].type, CollationType.delete);

      // Text2视图：只有EQUAL，没有DELETE
      expect(result.text2View.length, 1);
      expect(result.text2View[0].type, CollationType.equal);
      expect(result.text2View.every((c) => c.type != CollationType.delete), isTrue);

      // Merged视图：EQUAL + DELETE
      expect(result.mergedView.length, 2);
      expect(result.mergedView[1].type, CollationType.delete);
    });

    test('Text2 only insert - text1View has no insert segments', () {
      final text1 = '箇中';
      final text2 = '箇中學問';
      final options = CollationOptions(
        ignorePunctuation: false,
        ignoreTraditional: false,
        ignoreVariants: true,
      );

      final result = engine.compareWithFullContext(text1, text2, options: options);

      // Text1视图：只有EQUAL，没有INSERT
      expect(result.text1View.length, 1);
      expect(result.text1View[0].type, CollationType.equal);
      expect(result.text1View.every((c) => c.type != CollationType.insert), isTrue);

      // Text2视图：EQUAL + INSERT
      expect(result.text2View.length, 2);
      expect(result.text2View[0].type, CollationType.equal);
      expect(result.text2View[1].type, CollationType.insert);

      // Merged视图：EQUAL + INSERT
      expect(result.mergedView.length, 2);
      expect(result.mergedView[1].type, CollationType.insert);
    });
  });
}
