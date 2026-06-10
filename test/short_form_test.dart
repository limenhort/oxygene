import 'package:flutter_test/flutter_test.dart';
import 'package:oxygene/src/genome_short_form.dart';

/// Oxygene must expand the short form `old || buffer | count` into the same
/// tree as the interactive front canvas. mergeAll is private, so we verify
/// structurally: balance (leaves = forks + 1, no single-child nodes except
/// the root) and monotonic tree growth with the repeat count.
void main() {
  const life = "0,2-0*11v0,2-0*10v0,3-0*11v0,1-0*a,2-0*a,3-0*a,4-0*a";
  const buffer = "0,3-0*1v11,1-0*a,1-0*a";

  int leaves(String g) => g.split(',').where((t) => t.endsWith('*a')).length;
  int forks(String g) => g.split(',').where((t) => t.contains('v')).length;
  void expectBalanced(String g) =>
      expect(leaves(g), forks(g) + 1, reason: 'unbalanced: $g');

  test('flat genome expands to itself (no ||)', () {
    expect(GenomeShortForm.expand(life), life);
    expect(GenomeShortForm.isShort(life), isFalse);
  });

  test('| 1 grafts buffer into all leaves, tree stays balanced', () {
    final once = GenomeShortForm.expand('$life || $buffer | 1');
    expect(GenomeShortForm.isShort('$life || $buffer | 1'), isTrue);
    expect(once, isNot(life));
    expect(leaves(once), greaterThan(leaves(life)));
    expectBalanced(once);
  });

  test('counter grows tree monotonically, balance intact', () {
    final once = GenomeShortForm.expand('$life || $buffer | 1');
    final twice = GenomeShortForm.expand('$life || $buffer | 2');
    final thrice = GenomeShortForm.expand('$life || $buffer | 3');
    expect(leaves(twice), greaterThan(leaves(once)));
    expect(leaves(thrice), greaterThan(leaves(twice)));
    expectBalanced(twice);
    expectBalanced(thrice);
  });

  test('nested form (n+1 equivalent to wrap) yields same tree', () {
    // `… | 2` and `(… | 1) || buffer | 1` are the same tree
    final byCount = GenomeShortForm.expand('$life || $buffer | 2');
    final byNest = GenomeShortForm.expand('$life || $buffer | 1 || $buffer | 1');
    expect(byNest, byCount);
    expectBalanced(byNest);
  });

  test('bad/zero counter => 0 repeats, life unchanged', () {
    expect(GenomeShortForm.expand('$life || $buffer | 0'), life);
    expect(GenomeShortForm.expand('$life || $buffer | x'), life);
    expect(GenomeShortForm.expand('$life || $buffer'), life);
  });
}
