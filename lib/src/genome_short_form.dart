
class GenomeShortForm {
  static const String _graftSep = '||';
  static const String _countSep = '|';

  static bool isShort(String s) => s.contains(_graftSep);


  static String expand(String s) {
    final trimmed = s.trim();


    final cut = trimmed.lastIndexOf(_graftSep);
    if (cut < 0) return trimmed; // flat genome — nothing to expand

    final leftStr = trimmed.substring(0, cut);
    final rightStr = trimmed.substring(cut + _graftSep.length);


    final bar = rightStr.lastIndexOf(_countSep);
    if (bar < 0) return expand(leftStr);

    final bufferStr = rightStr.substring(0, bar);
    final countStr = rightStr.substring(bar + _countSep.length);
    final count = int.tryParse(countStr.trim()) ?? 0;

    var life = expand(leftStr);
    final buffer = expand(bufferStr);

    final merger = _GenomeMerger();
    for (var i = 0; i < count; i++) {
      life = merger.mergeAll(life: life, part: buffer);
    }
    return life;
  }
}

class _GenomeMerger {

  String mergeAll({required String life, required String part}) {
    final tokens = life.split(',').where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return life;

    final order = <_Node>[];
    final root = _parse(tokens, isGenomeRoot: true, order: order);
    if (root == null) return life;

    final subtreeTokens = _stripRotation(part);
    if (subtreeTokens.isEmpty) return life;

    final leaves = order.where((n) => n.children.isEmpty).toList();
    for (final leaf in leaves) {

      final graft = _parse(subtreeTokens, isGenomeRoot: false, order: <_Node>[]);
      if (graft == null) continue;

      leaf.token = _withTailOf(leaf.token, graft.token);
      leaf.children
        ..clear()
        ..addAll(graft.children);
    }
    return _serialize(root);
  }


  _Node? _parse(
    List<String> tokens, {
    required bool isGenomeRoot,
    required List<_Node> order,
  }) {
    if (tokens.isEmpty) return null;

    final root = _Node(tokens[0]);
    order.add(root);

    final queue = <_Node>[];
    final rootArity = isGenomeRoot ? 1 : _arity(tokens[0]);
    for (int k = 0; k < rootArity; k++) {
      queue.add(root);
    }

    int ti = 1;
    while (queue.isNotEmpty && ti < tokens.length) {
      final parent = queue.removeAt(0);
      final node = _Node(tokens[ti]);
      order.add(node);
      node.parent = parent;
      parent.children.add(node);
      for (int k = 0; k < _arity(tokens[ti]); k++) {
        queue.add(node);
      }
      ti++;
    }
    return root;
  }

  String _serialize(_Node root) {
    final out = <String>[];
    final queue = <_Node>[root];
    while (queue.isNotEmpty) {
      final n = queue.removeAt(0);
      out.add(n.token);
      queue.addAll(n.children);
    }
    return out.join(',');
  }

  String _withTailOf(String source, String donor) {
    final srcDash = source.indexOf('-');
    final dstDash = donor.indexOf('-');
    if (srcDash < 0 || dstDash < 0) return donor;
    return '${source.substring(0, srcDash)}${donor.substring(dstDash)}';
  }

  List<String> _stripRotation(String part) {
    final tokens = part.split(',').where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return tokens;
    return tokens.sublist(1);
  }

  int _arity(String token) {
    final parts = token.split('*');
    if (parts.length != 2) return 0;
    final head = parts[1];
    if (_isNum(head)) return 1;
    final lr = head.split('v');
    if (lr.length == 2 && _isNum(lr[0]) && _isNum(lr[1]) && lr[0] != lr[1]) {
      return 2;
    }
    return 0;
  }

  bool _isNum(String s) {
    const ok = {
      '0', '1', '2', '3', '4', '5', '7', '8', '9', '10', '11',
    };
    return ok.contains(s);
  }
}

class _Node {
  String token;
  _Node? parent;
  final List<_Node> children = [];
  _Node(this.token);
}
