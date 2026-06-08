import 'conllu_parser.dart';

enum UDPipeStatus { idle, loading, ready, error }

class UDSentenceResult {
  final String text;
  final Map<String, List<UDToken>> byFormAll;
  final List<SepVerb> sepVerbs;
  final List<UDToken> tokens;

  const UDSentenceResult({
    required this.text,
    required this.byFormAll,
    required this.sepVerbs,
    required this.tokens,
  });

  static const empty = UDSentenceResult(text: '', byFormAll: {}, sepVerbs: [], tokens: []);
}

class UDPipeResult {
  final List<UDSentenceResult> sentences;

  const UDPipeResult({required this.sentences});

  static const empty = UDPipeResult(sentences: []);
}

class UDPipeModelInfo {
  final String id;
  final String label;
  final String fileName;
  final String size;

  const UDPipeModelInfo({
    required this.id,
    required this.label,
    required this.fileName,
    required this.size,
  });
}

const kUdpipeModels = [
  UDPipeModelInfo(id: 'gsd', label: 'GSD (20 MB)', fileName: 'german-gsd.udpipe', size: '20 MB'),
  UDPipeModelInfo(id: 'hdt', label: 'HDT (60 MB)', fileName: 'german-hdt.udpipe', size: '60 MB'),
];

UDPipeModelInfo udpipeModelById(String id) =>
    kUdpipeModels.firstWhere((m) => m.id == id, orElse: () => kUdpipeModels.first);

// ── Shared result builders ─────────────────────────────────────────────────────

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
