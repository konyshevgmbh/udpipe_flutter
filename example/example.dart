// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:udpipe_flutter/udpipe_flutter.dart';

// ---------------------------------------------------------------------------
// UDPipe Flutter — usage examples
//
// This file shows all three ways to load a model and demonstrates the main
// API surface. It is not a runnable Flutter app — see lib/main.dart for that.
// ---------------------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Load by treebank id (file must be in assets/models/) ──────────────
  await exampleLoadById();

  // ── 2. Load from an arbitrary asset path ─────────────────────────────────
  await exampleLoadFromAsset();

  // ── 3. Load from bytes (e.g. downloaded at runtime) ──────────────────────
  await exampleLoadFromBytes();

  exit(0);
}

// ── Example 1: init(modelId:) ─────────────────────────────────────────────

Future<void> exampleLoadById() async {
  final svc = UDPipeService();

  // Pass the treebank id — the file german-gsd.udpipe must be in assets/models/.
  // See kUdpipeModels for the full list of ~94 available model ids.
  await svc.init(modelId: 'german-gsd');

  if (!svc.isAvailable) {
    print('[1] Model failed to load: ${svc.loadError}');
    return;
  }

  _printResult(svc.process('Er steigt aus dem Bus aus.'));

  svc.dispose();
}

// ── Example 2: initFromAsset(assetPath) ───────────────────────────────────

Future<void> exampleLoadFromAsset() async {
  final svc = UDPipeService();

  // Any path inside your Flutter assets — not limited to assets/models/.
  await svc.initFromAsset('assets/models/german-gsd.udpipe');

  if (!svc.isAvailable) {
    print('[2] Model failed to load: ${svc.loadError}');
    return;
  }

  _printResult(svc.process('Die Kinder spielen im Park.'));

  svc.dispose();
}

// ── Example 3: initFromBytes(bytes) ───────────────────────────────────────

Future<void> exampleLoadFromBytes() async {
  final svc = UDPipeService();

  // Bytes can come from anywhere: HTTP download, local file, shared preferences…
  final Uint8List bytes = await _fetchModelBytes();

  await svc.initFromBytes(bytes);

  if (!svc.isAvailable) {
    print('[3] Model failed to load: ${svc.loadError}');
    return;
  }

  // processAllBlocksAsync runs in a background isolate on native,
  // keeping the UI thread free for large inputs.
  final results = await svc.processAllBlocksAsync([
    'Er steigt aus dem Bus aus.',
    'Die Kinder spielen im Park.',
  ]);

  for (final result in results) {
    _printResult(result);
  }

  svc.dispose();
}

// ── Helpers ───────────────────────────────────────────────────────────────

void _printResult(UDPipeResult result) {
  for (final sentence in result.sentences) {
    print('Sentence: ${sentence.text}');
    for (final token in sentence.tokens) {
      print('  ${token.form.padRight(12)} ${token.upos.padRight(6)} ${token.lemma}');
    }
    for (final sv in sentence.sepVerbs) {
      print('  Separable verb: ${sv.particle}+${sv.verbForm} → ${sv.fullLemma}');
    }
  }
}

/// In production: replace with an HTTP download, local storage, etc.
/// Here we read the already-bundled model file to demonstrate the bytes path.
Future<Uint8List> _fetchModelBytes() async {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  final path = '$exeDir/data/flutter_assets/assets/models/german-gsd.udpipe';
  return File(path).readAsBytes();
}
