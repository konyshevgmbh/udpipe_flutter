// ignore_for_file: avoid_print

import 'package:udpipe_flutter/udpipe_flutter.dart';

/// Demonstrates UDPipe tokenization and POS tagging.
///
/// In a real Flutter app, call [UDPipeService.init] from an async context
/// (e.g. `initState`) and await it before calling [UDPipeService.process].
Future<void> main() async {
  final svc = UDPipeService();

  // Load a bundled model ('gsd' ≈ 20 MB, 'hdt' ≈ 60 MB).
  await svc.init(modelId: 'gsd');

  if (!svc.isAvailable) {
    print('Model failed to load: ${svc.loadError}');
    return;
  }

  final result = svc.process('Er steigt aus dem Bus aus.');

  for (final sentence in result.sentences) {
    print('Sentence: ${sentence.text}');
    for (final token in sentence.tokens) {
      print('  ${token.form.padRight(12)} ${token.upos.padRight(6)} ${token.lemma}');
    }
    for (final sv in sentence.sepVerbs) {
      print('  Separable verb: ${sv.particle} + ${sv.verbForm} → ${sv.fullLemma}');
    }
  }

  svc.dispose();
}
