import 'conllu_parser.dart';

/// Loading state of [UDPipeService].
enum UDPipeStatus {
  /// No model has been requested yet.
  idle,

  /// A model is currently being loaded.
  loading,

  /// A model is loaded and [UDPipeService.process] can be called.
  ready,

  /// Model loading failed; check [UDPipeService.loadError] for details.
  error,
}

/// Parsed result for a single sentence.
class UDSentenceResult {
  /// Original sentence text as reported by UDPipe.
  final String text;

  /// All tokens grouped by surface form (and lowercase form).
  final Map<String, List<UDToken>> byFormAll;

  /// Separable verbs detected in this sentence.
  final List<SepVerb> sepVerbs;

  /// Tokens in sentence order.
  final List<UDToken> tokens;

  const UDSentenceResult({
    required this.text,
    required this.byFormAll,
    required this.sepVerbs,
    required this.tokens,
  });

  static const empty = UDSentenceResult(text: '', byFormAll: {}, sepVerbs: [], tokens: []);
}

/// Result returned by [UDPipeService.process], containing one entry per sentence.
class UDPipeResult {
  /// Parsed sentences in input order.
  final List<UDSentenceResult> sentences;

  const UDPipeResult({required this.sentences});

  static const empty = UDPipeResult(sentences: []);
}

/// Metadata for an available UDPipe model.
class UDPipeModelInfo {
  /// Short identifier used with [UDPipeService.init] (e.g. `'gsd'`).
  final String id;

  /// Human-readable label shown in the UI.
  final String label;

  /// Asset filename inside `assets/models/`.
  final String fileName;

  /// Approximate on-disk size, for display purposes.
  final String size;

  const UDPipeModelInfo({
    required this.id,
    required this.label,
    required this.fileName,
    required this.size,
  });
}

/// Bundled German models. Pass [UDPipeModelInfo.id] to [UDPipeService.init].
const kUdpipeModels = [
  UDPipeModelInfo(id: 'gsd', label: 'GSD (20 MB)', fileName: 'german-gsd.udpipe', size: '20 MB'),
  UDPipeModelInfo(id: 'hdt', label: 'HDT (60 MB)', fileName: 'german-hdt.udpipe', size: '60 MB'),
];

/// Returns the [UDPipeModelInfo] for [id], falling back to the first model.
UDPipeModelInfo udpipeModelById(String id) =>
    kUdpipeModels.firstWhere((m) => m.id == id, orElse: () => kUdpipeModels.first);

// ── Shared result builders ─────────────────────────────────────────────────────

/// Converts a raw CoNLL-U [conllu] string into a [UDPipeResult].
UDPipeResult buildUDPipeResult(String conllu) {
  return UDPipeResult(sentences: [
    for (final s in parseConlluSentences(conllu))
      UDSentenceResult(
        text: s.text,
        byFormAll: tokensByFormAll(s.tokens),
        sepVerbs: findSepVerbs(s.tokens),
        tokens: s.tokens,
      ),
  ]);
}

/// Splits a multi-sentence CoNLL-U string into one [UDPipeResult] per input block.
List<UDPipeResult> splitUDPipeResultByBlocks(String conllu, List<String> blocks) {
  final parsed = parseConlluSentences(conllu);
  final blockSents = List.generate(blocks.length, (_) => <UDSentenceResult>[]);
  int bi = 0;
  for (final s in parsed) {
    while (bi < blocks.length) {
      if (blocks[bi].contains(s.text)) {
        blockSents[bi].add(UDSentenceResult(
          text: s.text,
          byFormAll: tokensByFormAll(s.tokens),
          sepVerbs: findSepVerbs(s.tokens),
          tokens: s.tokens,
        ));
        break;
      }
      bi++;
    }
  }
  return [for (final sents in blockSents) UDPipeResult(sentences: sents)];
}
