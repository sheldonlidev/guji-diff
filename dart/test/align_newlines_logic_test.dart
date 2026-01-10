import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Align Newlines Logic', () {
    // Copy of the function for testing
    void alignNewlines(List<Diff> diffs) {
      final result = <Diff>[];
      int i = 0;

      while (i < diffs.length) {
        if (diffs[i].operation == DIFF_EQUAL) {
          result.add(diffs[i]);
          i++;
          continue;
        }

        final block = <Diff>[];
        while (i < diffs.length && diffs[i].operation != DIFF_EQUAL) {
          block.add(diffs[i]);
          i++;
        }

        final delBuffer = StringBuffer();
        final insBuffer = StringBuffer();
        for (final d in block) {
          if (d.operation == DIFF_DELETE) delBuffer.write(d.text);
          if (d.operation == DIFF_INSERT) insBuffer.write(d.text);
        }
        final delText = delBuffer.toString();
        final insText = insBuffer.toString();

        if (delText.contains('\n') && insText.contains('\n')) {
          final delParts = delText.split('\n');
          final insParts = insText.split('\n');
          final count = delParts.length > insParts.length
              ? delParts.length
              : insParts.length;

          for (int k = 0; k < count; k++) {
            final dPart = k < delParts.length ? delParts[k] : null;
            final iPart = k < insParts.length ? insParts[k] : null;

            if (dPart != null && dPart.isNotEmpty) {
              result.add(Diff(DIFF_DELETE, dPart));
            }
            if (iPart != null && iPart.isNotEmpty) {
              result.add(Diff(DIFF_INSERT, iPart));
            }

            final hasDelSep = k < delParts.length - 1;
            final hasInsSep = k < insParts.length - 1;

            if (hasDelSep && hasInsSep) {
              result.add(Diff(DIFF_EQUAL, '\n'));
            } else if (hasDelSep) {
              result.add(Diff(DIFF_DELETE, '\n'));
            } else if (hasInsSep) {
              result.add(Diff(DIFF_INSERT, '\n'));
            }
          }
        } else {
          result.addAll(block);
        }
      }

      diffs.clear();
      diffs.addAll(result);
    }

    test('Basic alignment', () {
      final diffs = [Diff(DIFF_DELETE, 'A\nB'), Diff(DIFF_INSERT, 'X\nY')];
      alignNewlines(diffs);

      expect(diffs.length, 5);
      expect(diffs[0].operation, DIFF_DELETE);
      expect(diffs[0].text, 'A');
      expect(diffs[1].operation, DIFF_INSERT);
      expect(diffs[1].text, 'X');
      expect(diffs[2].operation, DIFF_EQUAL);
      expect(diffs[2].text, '\n');
      expect(diffs[3].operation, DIFF_DELETE);
      expect(diffs[3].text, 'B');
      expect(diffs[4].operation, DIFF_INSERT);
      expect(diffs[4].text, 'Y');
    });

    test('Mixed newline counts', () {
      final diffs = [Diff(DIFF_DELETE, 'A\nB'), Diff(DIFF_INSERT, 'X')];
      alignNewlines(diffs);
      // No alignment because INSERT has no newline
      expect(diffs.length, 2);
    });

    test('Unaligned newlines (deleted newline but inserted no newline)', () {
      final diffs = [Diff(DIFF_DELETE, 'A\nB'), Diff(DIFF_INSERT, 'X\n')];
      // Del has 1 newline. Ins has 1 newline.
      // A\nB -> ['A', 'B']
      // X\n -> ['X', '']
      // Align!
      alignNewlines(diffs);

      // k=0: Del(A), Ins(X). Sep(T, T) -> Equal(\n)
      // k=1: Del(B), Ins(). Sep(F, F).
      // Result: Del(A), Ins(X), Eq(\n), Del(B).
      expect(diffs.length, 4);
      expect(diffs[2].operation, DIFF_EQUAL);
      expect(diffs[2].text, '\n');
    });

    test('Multiple newlines alignment', () {
      final diffs = [Diff(DIFF_DELETE, '\n\n'), Diff(DIFF_INSERT, '\n\n')];
      alignNewlines(diffs);
      // \n\n -> ['', '', ''] (len 3)
      // k=0: Sep(T,T) -> Equal(\n)
      // k=1: Sep(T,T) -> Equal(\n)
      // k=2: Sep(F,F) -> nothing
      expect(diffs.length, 2);
      expect(
        diffs.every((d) => d.operation == DIFF_EQUAL && d.text == '\n'),
        isTrue,
      );
    });
  });
}
