import 'dart:convert';
import 'dart:io';
import 'package:guji_diff/guji_diff.dart';

void main(List<String> args) {
  if (args.length < 2) {
    print('Usage: guji_diff <input1> <input2> [options]');
    print('Options:');
    print(
      '  --structural          Compare as structured JSON files (Document model)',
    );
    print(
      '  --analyze             Generate statistical analysis report (JSON)',
    );
    print('  --ignore-punctuation  Ignore punctuation');
    print('  --ignore-traditional  Ignore traditional/simplified differences');
    print('  --ignore-variants     Ignore variant characters');
    return;
  }

  final input1 = args[0];
  final input2 = args[1];
  final isStructural = args.contains('--structural');
  final isAnalyze = args.contains('--analyze');

  final options = CollationOptions(
    ignorePunctuation: args.contains('--ignore-punctuation'),
    ignoreTraditional: args.contains('--ignore-traditional'),
    ignoreVariants: args.contains('--ignore-variants'),
  );

  if (isAnalyze) {
    _handleAnalysis(input1, input2, options);
  } else if (isStructural) {
    _handleStructural(input1, input2, options);
  } else {
    _handleVerbatim(input1, input2, options);
  }
}

void _handleAnalysis(String text1, String text2, CollationOptions options) {
  final engine = VerbatimCollation();
  final changes = engine.compare(text1, text2, options: options);

  final similarity = SimilarityScorer.calculate(changes);
  final patterns = ChangePatternAnalyzer.analyze(changes);

  final report = AnalysisReport(
    similarity: similarity,
    patterns: patterns,
    totalChanges: changes.where((c) => c.type != CollationType.equal).length,
  );

  print('Statistical Analysis Report (JSON):');
  print(JsonEncoder.withIndent('  ').convert(report.toJson()));
}

void _handleVerbatim(String text1, String text2, CollationOptions options) {
  final engine = VerbatimCollation();
  final changes = engine.compare(text1, text2, options: options);

  print('Verbatim Collation Results:');
  for (var change in changes) {
    String typeStr;
    switch (change.type) {
      case CollationType.insert:
        typeStr = '[+]';
        break;
      case CollationType.delete:
        typeStr = '[-]';
        break;
      case CollationType.equal:
        typeStr = '[=]';
        break;
    }
    print('$typeStr ${change.text}');
  }
}

void _handleStructural(String path1, String path2, CollationOptions options) {
  final file1 = File(path1);
  final file2 = File(path2);

  if (!file1.existsSync() || !file2.existsSync()) {
    print('Error: JSON files not found.');
    return;
  }

  final doc1Json = jsonDecode(file1.readAsStringSync());
  final doc2Json = jsonDecode(file2.readAsStringSync());

  final doc1 = _parseDoc(doc1Json);
  final doc2 = _parseDoc(doc2Json);

  final engine = StructuralCollation();
  final diffs = engine.compareDocuments(doc1, doc2, options: options);
  final patch = JsonPatchConverter.convert(diffs);

  print('Structural Collation Results (JSON Patch):');
  print(JsonEncoder.withIndent('  ').convert(patch));
}

Document _parseDoc(dynamic json) {
  final chapters = (json['chapters'] as List).map((c) {
    final paragraphs = (c['paragraphs'] as List).map((p) {
      return Paragraph(
        id: p['id']?.toString() ?? '',
        content: p['content'] ?? '',
      );
    }).toList();
    return Chapter(title: c['title'] ?? '', paragraphs: paragraphs);
  }).toList();
  return Document(chapters: chapters);
}
