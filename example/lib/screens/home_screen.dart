import 'package:flutter/material.dart';
import 'package:udpipe_flutter/udpipe_flutter.dart';

const _kSampleTexts = [
  'Er steigt aus dem Bus aus.',
  'Die Kinder spielen im Park.',
  'Das Buch wurde von Goethe geschrieben.',
  'Ich habe gestern einen interessanten Film gesehen.',
  'Sie fährt jeden Morgen mit dem Fahrrad zur Arbeit.',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ctrl = TextEditingController(text: _kSampleTexts.first);
  final _svc  = UDPipeService();

  String _modelId = 'german-gsd';
  UDPipeResult? _result;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _svc.status.addListener(_onStatus);
  }

  @override
  void dispose() {
    _svc.status.removeListener(_onStatus);
    _ctrl.dispose();
    super.dispose();
  }

  void _onStatus() => setState(() {});

  Future<void> _onModelChanged(String? id) async {
    if (id == null || id == _modelId) return;
    setState(() { _modelId = id; _result = null; });
    await _svc.init(modelId: id);
  }

  Future<void> _analyze() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (!_svc.isAvailable) {
      await _svc.init(modelId: _modelId);
    }
    setState(() { _processing = true; _result = null; });
    try {
      final r = _svc.process(text);
      setState(() { _result = r; });
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = _svc.status.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UDPipe Flutter'),
        backgroundColor: cs.primaryContainer,
      ),
      body: Column(
        children: [
          // ── Input area ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sample sentences
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _kSampleTexts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) => ActionChip(
                      label: Text(_kSampleTexts[i], style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        _ctrl.text = _kSampleTexts[i];
                        _analyze();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ctrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter text to analyze…',
                    labelText: 'Input text',
                  ),
                ),
                const SizedBox(height: 8),
                // Model selector + status + analyze button
                Row(
                  children: [
                    const Text('Model:'),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _modelId,
                      items: kUdpipeModels.map((m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.label),
                      )).toList(),
                      onChanged: _onModelChanged,
                    ),
                    const SizedBox(width: 12),
                    Flexible(child: _StatusBadge(status: status, error: _svc.loadError)),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _processing ? null : _analyze,
                      icon: _processing
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.play_arrow),
                      label: const Text('Analyze'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // ── Results ───────────────────────────────────────────────────────
          Expanded(
            child: _result == null
                ? Center(
                    child: Text(
                      'Enter text and press Analyze',
                      style: TextStyle(color: cs.outline),
                    ),
                  )
                : _result!.sentences.isEmpty
                    ? Center(
                        child: Text(
                          'No output (forms mode returns empty CoNLL-U)',
                          style: TextStyle(color: cs.outline),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _result!.sentences.length,
                        itemBuilder: (_, si) {
                          final sent = _result!.sentences[si];
                          return _SentenceCard(sentence: sent, index: si);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final UDPipeStatus status;
  final String? error;
  const _StatusBadge({required this.status, this.error});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      UDPipeStatus.idle    => const SizedBox.shrink(),
      UDPipeStatus.loading => const Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 6),
          Text('Loading…', style: TextStyle(fontSize: 12)),
        ]),
      UDPipeStatus.ready   => const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, size: 14, color: Color(0xFF27AE60)),
          SizedBox(width: 4),
          Text('Ready', style: TextStyle(fontSize: 12, color: Color(0xFF27AE60))),
        ]),
      UDPipeStatus.error   => Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 14, color: Colors.red),
          const SizedBox(width: 4),
          Flexible(child: Text(
            error ?? 'Error',
            style: const TextStyle(fontSize: 11, color: Colors.red),
            overflow: TextOverflow.ellipsis,
          )),
        ]),
    };
  }
}

class _SentenceCard extends StatelessWidget {
  final UDSentenceResult sentence;
  final int index;
  const _SentenceCard({required this.sentence, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sepVerbSet = {for (final sv in sentence.sepVerbs) sv.verbForm.toLowerCase()};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sentence header
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('S${index + 1}', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(
                sentence.text,
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
              )),
            ]),
            // Separable verbs
            if (sentence.sepVerbs.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  const Text('Sep. verbs:', style: TextStyle(fontSize: 11)),
                  for (final sv in sentence.sepVerbs)
                    Chip(
                      label: Text('${sv.fullLemma}  (${sv.particle}+${sv.verbForm})',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF90CAF9))),
                      backgroundColor: const Color(0xFF0D47A1),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Token table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 28,
                dataRowMinHeight: 26,
                dataRowMaxHeight: 32,
                columnSpacing: 12,
                columns: const [
                  DataColumn(label: Text('#',      style: TextStyle(fontSize: 11))),
                  DataColumn(label: Text('Form',   style: TextStyle(fontSize: 11))),
                  DataColumn(label: Text('Lemma',  style: TextStyle(fontSize: 11))),
                  DataColumn(label: Text('UPOS',   style: TextStyle(fontSize: 11))),
                  DataColumn(label: Text('Deprel', style: TextStyle(fontSize: 11))),
                  DataColumn(label: Text('Head',   style: TextStyle(fontSize: 11))),
                ],
                rows: sentence.tokens.map((t) {
                  final isSep = sepVerbSet.contains(t.form.toLowerCase());
                  return DataRow(
                    color: isSep
                        ? WidgetStateProperty.all(const Color(0xFF1A2F1A))
                        : null,
                    cells: [
                      DataCell(Text('${t.id}', style: const TextStyle(fontSize: 11))),
                      DataCell(Text(t.form,   style: TextStyle(fontSize: 12,
                          fontWeight: isSep ? FontWeight.bold : FontWeight.normal))),
                      DataCell(Text(t.lemma,  style: const TextStyle(fontSize: 11))),
                      DataCell(_UposBadge(upos: t.upos)),
                      DataCell(Text(t.deprel, style: const TextStyle(fontSize: 11))),
                      DataCell(Text('${t.head}', style: const TextStyle(fontSize: 11))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UposBadge extends StatelessWidget {
  final String upos;
  const _UposBadge({required this.upos});

  static const _palette = <String, (Color, Color)>{
    'VERB':  (Color(0xFF1B5E20), Color(0xFF69F0AE)),
    'AUX':   (Color(0xFF1B5E20), Color(0xFF69F0AE)),
    'NOUN':  (Color(0xFF0D47A1), Color(0xFF82B1FF)),
    'PROPN': (Color(0xFF0D47A1), Color(0xFF82B1FF)),
    'ADJ':   (Color(0xFFE65100), Color(0xFFFFCC80)),
    'ADV':   (Color(0xFFBF360C), Color(0xFFFFCC80)),
    'ADP':   (Color(0xFF4A148C), Color(0xFFEA80FC)),
    'DET':   (Color(0xFF4A148C), Color(0xFFEA80FC)),
    'PRON':  (Color(0xFF880E4F), Color(0xFFFF80AB)),
    'CCONJ': (Color(0xFF004D40), Color(0xFF64FFDA)),
    'SCONJ': (Color(0xFF004D40), Color(0xFF64FFDA)),
    'PART':  (Color(0xFF3E2723), Color(0xFFBCAAA4)),
    'NUM':   (Color(0xFF1A237E), Color(0xFF80D8FF)),
    'PUNCT': (Color(0xFF263238), Color(0xFF90A4AE)),
    'SYM':   (Color(0xFF263238), Color(0xFF90A4AE)),
    'X':     (Color(0xFF212121), Color(0xFFBDBDBD)),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _palette[upos] ?? (const Color(0xFF37474F), const Color(0xFFB0BEC5));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(upos, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
