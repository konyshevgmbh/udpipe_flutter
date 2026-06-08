import 'package:flutter/material.dart';
import '../udpipe/udpipe_flutter.dart';

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

  String _modelId = 'gsd';
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
                    _StatusBadge(status: status, error: _svc.loadError),
                    const Spacer(),
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
                children: [
                  const Text('Sep. verbs:', style: TextStyle(fontSize: 11)),
                  for (final sv in sentence.sepVerbs)
                    Chip(
                      label: Text('${sv.fullLemma}  (${sv.particle}+${sv.verbForm})',
                          style: const TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFE3F2FD),
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
                        ? WidgetStateProperty.all(const Color(0xFFFFF8E1))
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

  static const _colors = {
    'VERB': Color(0xFFE8F5E9), 'AUX':  Color(0xFFE8F5E9),
    'NOUN': Color(0xFFE3F2FD), 'PROPN':Color(0xFFE3F2FD),
    'ADJ':  Color(0xFFFFF9C4), 'ADV':  Color(0xFFFFF9C4),
    'ADP':  Color(0xFFFCE4EC), 'DET':  Color(0xFFFCE4EC),
  };

  @override
  Widget build(BuildContext context) {
    final bg = _colors[upos] ?? const Color(0xFFF5F5F5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
      child: Text(upos, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
