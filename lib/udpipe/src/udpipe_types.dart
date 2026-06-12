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

  /// An empty sentence result used as a safe default.
  static const empty = UDSentenceResult(text: '', byFormAll: {}, sepVerbs: [], tokens: []);
}

/// Result returned by [UDPipeService.process], containing one entry per sentence.
class UDPipeResult {
  /// Parsed sentences in input order.
  final List<UDSentenceResult> sentences;

  const UDPipeResult({required this.sentences});

  /// An empty result used as a safe default when no model is loaded.
  static const empty = UDPipeResult(sentences: []);
}

/// Metadata for an available UDPipe model.
class UDPipeModelInfo {
  /// Treebank identifier used with [UDPipeService.init] (e.g. `'german-gsd'`).
  final String id;

  /// Human-readable label shown in the UI.
  final String label;

  /// Asset filename inside `assets/models/` — derived from [id].
  String get fileName => '$id.udpipe';

  const UDPipeModelInfo({required this.id, required this.label});
}

/// All UDPipe 1 models (UD 2.5). Pass [UDPipeModelInfo.id] to [UDPipeService.init].
const kUdpipeModels = [
  // Ancient Greek
  UDPipeModelInfo(id: 'ancient_greek-perseus',          label: 'Ancient Greek — PERSEUS'),
  UDPipeModelInfo(id: 'ancient_greek-proiel',           label: 'Ancient Greek — PROIEL'),
  // Arabic
  UDPipeModelInfo(id: 'arabic-padt',                    label: 'Arabic — PADT'),
  // Basque
  UDPipeModelInfo(id: 'basque-bdt',                     label: 'Basque — BDT'),
  // Belarusian
  UDPipeModelInfo(id: 'belarusian-hse',                 label: 'Belarusian — HSE'),
  // Bulgarian
  UDPipeModelInfo(id: 'bulgarian-btb',                  label: 'Bulgarian — BTB'),
  // Catalan
  UDPipeModelInfo(id: 'catalan-ancora',                 label: 'Catalan — AnCora'),
  // Chinese
  UDPipeModelInfo(id: 'chinese-gsd',                    label: 'Chinese — GSD'),
  // Coptic
  UDPipeModelInfo(id: 'coptic-scriptorium',             label: 'Coptic — Scriptorium'),
  // Croatian
  UDPipeModelInfo(id: 'croatian-set',                   label: 'Croatian — SET'),
  // Czech
  UDPipeModelInfo(id: 'czech-cac',                      label: 'Czech — CAC'),
  UDPipeModelInfo(id: 'czech-cltt',                     label: 'Czech — CLTT'),
  UDPipeModelInfo(id: 'czech-fictree',                  label: 'Czech — FicTree'),
  UDPipeModelInfo(id: 'czech-pdt',                      label: 'Czech — PDT'),
  // Danish
  UDPipeModelInfo(id: 'danish-ddt',                     label: 'Danish — DDT'),
  // Dutch
  UDPipeModelInfo(id: 'dutch-alpino',                   label: 'Dutch — Alpino'),
  UDPipeModelInfo(id: 'dutch-lassysmall',               label: 'Dutch — LassySmall'),
  // English
  UDPipeModelInfo(id: 'english-ewt',                    label: 'English — EWT'),
  UDPipeModelInfo(id: 'english-gum',                    label: 'English — GUM'),
  UDPipeModelInfo(id: 'english-lines',                  label: 'English — LinES'),
  UDPipeModelInfo(id: 'english-partut',                 label: 'English — ParTUT'),
  // Estonian
  UDPipeModelInfo(id: 'estonian-edt',                   label: 'Estonian — EDT'),
  UDPipeModelInfo(id: 'estonian-ewt',                   label: 'Estonian — EWT'),
  // Finnish
  UDPipeModelInfo(id: 'finnish-ftb',                    label: 'Finnish — FTB'),
  UDPipeModelInfo(id: 'finnish-tdt',                    label: 'Finnish — TDT'),
  // French
  UDPipeModelInfo(id: 'french-gsd',                     label: 'French — GSD'),
  UDPipeModelInfo(id: 'french-partut',                  label: 'French — ParTUT'),
  UDPipeModelInfo(id: 'french-sequoia',                 label: 'French — Sequoia'),
  UDPipeModelInfo(id: 'french-spoken',                  label: 'French — Spoken'),
  // Galician
  UDPipeModelInfo(id: 'galician-ctg',                   label: 'Galician — CTG'),
  UDPipeModelInfo(id: 'galician-treegal',               label: 'Galician — TreeGal'),
  // German
  UDPipeModelInfo(id: 'german-gsd',                     label: 'German — GSD'),
  UDPipeModelInfo(id: 'german-hdt',                     label: 'German — HDT'),
  // Gothic
  UDPipeModelInfo(id: 'gothic-proiel',                  label: 'Gothic — PROIEL'),
  // Greek
  UDPipeModelInfo(id: 'greek-gdt',                      label: 'Greek — GDT'),
  // Hebrew
  UDPipeModelInfo(id: 'hebrew-htb',                     label: 'Hebrew — HTB'),
  // Hindi
  UDPipeModelInfo(id: 'hindi-hdtb',                     label: 'Hindi — HDTB'),
  // Hungarian
  UDPipeModelInfo(id: 'hungarian-szeged',               label: 'Hungarian — Szeged'),
  // Indonesian
  UDPipeModelInfo(id: 'indonesian-gsd',                 label: 'Indonesian — GSD'),
  // Irish
  UDPipeModelInfo(id: 'irish-idt',                      label: 'Irish — IDT'),
  // Italian
  UDPipeModelInfo(id: 'italian-isdt',                   label: 'Italian — ISDT'),
  UDPipeModelInfo(id: 'italian-partut',                 label: 'Italian — ParTUT'),
  UDPipeModelInfo(id: 'italian-postwita',               label: 'Italian — PoSTWITA'),
  UDPipeModelInfo(id: 'italian-twittiro',               label: 'Italian — Twittirò'),
  // Japanese
  UDPipeModelInfo(id: 'japanese-gsd',                   label: 'Japanese — GSD'),
  // Korean
  UDPipeModelInfo(id: 'korean-gsd',                     label: 'Korean — GSD'),
  UDPipeModelInfo(id: 'korean-kaist',                   label: 'Korean — KAIST'),
  // Latin
  UDPipeModelInfo(id: 'latin-ittb',                     label: 'Latin — ITTB'),
  UDPipeModelInfo(id: 'latin-perseus',                  label: 'Latin — Perseus'),
  UDPipeModelInfo(id: 'latin-proiel',                   label: 'Latin — PROIEL'),
  // Latvian
  UDPipeModelInfo(id: 'latvian-lvtb',                   label: 'Latvian — LVTB'),
  // Lithuanian
  UDPipeModelInfo(id: 'lithuanian-alksnis',             label: 'Lithuanian — ALKSNIS'),
  UDPipeModelInfo(id: 'lithuanian-hse',                 label: 'Lithuanian — HSE'),
  // Maltese
  UDPipeModelInfo(id: 'maltese-mudt',                   label: 'Maltese — MUDT'),
  // Marathi
  UDPipeModelInfo(id: 'marathi-ufal',                   label: 'Marathi — UFAL'),
  // North Sami
  UDPipeModelInfo(id: 'north_sami-giella',              label: 'North Sami — Giella'),
  // Norwegian
  UDPipeModelInfo(id: 'norwegian-bokmaal',              label: 'Norwegian — Bokmål'),
  UDPipeModelInfo(id: 'norwegian-nynorsk',              label: 'Norwegian — Nynorsk'),
  UDPipeModelInfo(id: 'norwegian-nynorsklia',           label: 'Norwegian — NynorskLIA'),
  // Old Church Slavonic
  UDPipeModelInfo(id: 'old_church_slavonic-proiel',     label: 'Old Church Slavonic — PROIEL'),
  // Old French
  UDPipeModelInfo(id: 'old_french-srcmf',               label: 'Old French — SRCMF'),
  // Old Russian
  UDPipeModelInfo(id: 'old_russian-torot',              label: 'Old Russian — TOROT'),
  // Persian
  UDPipeModelInfo(id: 'persian-seraji',                 label: 'Persian — Seraji'),
  // Polish
  UDPipeModelInfo(id: 'polish-lfg',                     label: 'Polish — LFG'),
  UDPipeModelInfo(id: 'polish-pdb',                     label: 'Polish — PDB'),
  // Portuguese
  UDPipeModelInfo(id: 'portuguese-bosque',              label: 'Portuguese — Bosque'),
  UDPipeModelInfo(id: 'portuguese-gsd',                 label: 'Portuguese — GSD'),
  // Romanian
  UDPipeModelInfo(id: 'romanian-nonstandard',           label: 'Romanian — Nonstandard'),
  UDPipeModelInfo(id: 'romanian-rrt',                   label: 'Romanian — RRT'),
  // Russian
  UDPipeModelInfo(id: 'russian-gsd',                    label: 'Russian — GSD'),
  UDPipeModelInfo(id: 'russian-syntagrus',              label: 'Russian — SynTagRus'),
  UDPipeModelInfo(id: 'russian-taiga',                  label: 'Russian — Taiga'),
  // Serbian
  UDPipeModelInfo(id: 'serbian-set',                    label: 'Serbian — SET'),
  // Slovak
  UDPipeModelInfo(id: 'slovak-snk',                     label: 'Slovak — SNK'),
  // Slovenian
  UDPipeModelInfo(id: 'slovenian-ssj',                  label: 'Slovenian — SSJ'),
  UDPipeModelInfo(id: 'slovenian-sst',                  label: 'Slovenian — SST'),
  // Spanish
  UDPipeModelInfo(id: 'spanish-ancora',                 label: 'Spanish — AnCora'),
  UDPipeModelInfo(id: 'spanish-gsd',                    label: 'Spanish — GSD'),
  // Swedish
  UDPipeModelInfo(id: 'swedish-lines',                  label: 'Swedish — LinES'),
  UDPipeModelInfo(id: 'swedish-talbanken',              label: 'Swedish — Talbanken'),
  // Swedish Sign Language
  UDPipeModelInfo(id: 'swedish_sign_language-sweslam', label: 'Swedish Sign Language — SWESLAM'),
  // Tamil
  UDPipeModelInfo(id: 'tamil-ttb',                      label: 'Tamil — TTB'),
  // Telugu
  UDPipeModelInfo(id: 'telugu-mtg',                     label: 'Telugu — MTG'),
  // Turkish
  UDPipeModelInfo(id: 'turkish-imst',                   label: 'Turkish — IMST'),
  // Ukrainian
  UDPipeModelInfo(id: 'ukrainian-iu',                   label: 'Ukrainian — IU'),
  // Upper Sorbian
  UDPipeModelInfo(id: 'upper_sorbian-ufal',             label: 'Upper Sorbian — UFAL'),
  // Urdu
  UDPipeModelInfo(id: 'urdu-udtb',                      label: 'Urdu — UDTB'),
  // Uyghur
  UDPipeModelInfo(id: 'uyghur-udt',                     label: 'Uyghur — UDT'),
  // Vietnamese
  UDPipeModelInfo(id: 'vietnamese-vtb',                 label: 'Vietnamese — VTB'),
  // Wolof
  UDPipeModelInfo(id: 'wolof-wtb',                      label: 'Wolof — WTB'),
];

/// Legacy short-id aliases from before 0.2.0 (both were German-only).
const _kLegacyIds = {'gsd': 'german-gsd', 'hdt': 'german-hdt'};

/// Returns the [UDPipeModelInfo] for [id].
///
/// Accepts legacy short ids (`'gsd'`, `'hdt'`) for backward compatibility.
/// Throws [ArgumentError] if [id] is not in [kUdpipeModels].
UDPipeModelInfo udpipeModelById(String id) {
  final resolved = _kLegacyIds[id] ?? id;
  return kUdpipeModels.firstWhere((m) => m.id == resolved,
      orElse: () => throw ArgumentError.value(
          id, 'modelId', 'Unknown model id. See kUdpipeModels for valid ids.'));
}

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
