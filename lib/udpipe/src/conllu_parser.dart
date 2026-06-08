/// A single token from a CoNLL-U sentence produced by UDPipe.
class UDToken {
  /// 1-based token index within the sentence.
  final int    id;

  /// Surface form as it appears in the input text.
  final String form;

  /// Dictionary lemma.
  final String lemma;

  /// Universal POS tag (VERB, NOUN, ADJ, …).
  final String upos;

  /// Universal dependency relation (root, nsubj, obj, …).
  final String deprel;

  /// [id] of the syntactic head token; 0 means root.
  final int    head;

  const UDToken({
    required this.id,
    required this.form,
    required this.lemma,
    required this.upos,
    required this.deprel,
    required this.head,
  });
}

/// A German separable verb detected in a sentence
/// (e.g. *aussteigen* split into particle *aus* + verb stem *steigt*).
class SepVerb {
  /// Reconstructed full lemma: `particle.toLowerCase() + verb.lemma`,
  /// e.g. `"aus"` + `"steigen"` → `"aussteigen"`.
  final String fullLemma;

  /// Inflected verb form found in the sentence (e.g. `"steigt"`).
  final String verbForm;

  /// Detached particle (e.g. `"aus"`).
  final String particle;

  const SepVerb({
    required this.fullLemma,
    required this.verbForm,
    required this.particle,
  });
}

// ── Parser ─────────────────────────────────────────────────────────────────────

List<UDToken> parseConllu(String conllu) {
  final tokens = <UDToken>[];
  for (final line in conllu.split('\n')) {
    if (line.isEmpty || line.startsWith('#')) continue;
    final p = line.split('\t');
    if (p.length < 8) continue;
    if (p[0].contains('-') || p[0].contains('.')) continue;
    final id = int.tryParse(p[0]);
    if (id == null) continue;
    tokens.add(UDToken(
      id:     id,
      form:   p[1],
      lemma:  p[2],
      upos:   p[3],
      deprel: p[7],
      head:   int.tryParse(p[6]) ?? 0,
    ));
  }
  return tokens;
}

/// Finds all separated (trennbar) verbs in a token list.
List<SepVerb> findSepVerbs(List<UDToken> tokens) {
  final result = <SepVerb>[];
  for (final t in tokens) {
    final dep = t.deprel.toLowerCase();
    if (!dep.contains('prt') && dep != 'svp') continue;
    if (t.upos == 'VERB' || t.upos == 'AUX') continue;
    final head = tokens.where((h) => h.id == t.head).firstOrNull;
    if (head == null || head.upos != 'VERB') continue;
    result.add(SepVerb(
      fullLemma: t.form.toLowerCase() + head.lemma,
      verbForm:  head.form,
      particle:  t.form,
    ));
  }
  return result;
}

/// Builds a map from surface form → all tokens with that form, in order.
Map<String, List<UDToken>> tokensByFormAll(List<UDToken> tokens) {
  final map = <String, List<UDToken>>{};
  for (final t in tokens) {
    (map[t.form] ??= []).add(t);
    final lower = t.form.toLowerCase();
    if (lower != t.form) (map[lower] ??= []).add(t);
  }
  return map;
}

/// Parses a batch CoNLL-U string into per-sentence records.
List<({String text, List<UDToken> tokens})> parseConlluSentences(String conllu) {
  final result = <({String text, List<UDToken> tokens})>[];
  String sentText = '';
  final current = <UDToken>[];

  void flush() {
    if (current.isNotEmpty) {
      result.add((text: sentText, tokens: List.unmodifiable(current)));
      current.clear();
      sentText = '';
    }
  }

  for (final line in conllu.split('\n')) {
    if (line.startsWith('# text = ')) {
      sentText = line.substring('# text = '.length).trim();
    } else if (line.isEmpty || line == '\r') {
      flush();
    } else if (!line.startsWith('#')) {
      final p = line.split('\t');
      if (p.length < 8) continue;
      if (p[0].contains('-') || p[0].contains('.')) continue;
      final id = int.tryParse(p[0]);
      if (id == null) continue;
      current.add(UDToken(
        id:     id,
        form:   p[1],
        lemma:  p[2],
        upos:   p[3],
        deprel: p[7],
        head:   int.tryParse(p[6]) ?? 0,
      ));
    }
  }
  flush();
  return result;
}
