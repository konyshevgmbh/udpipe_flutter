# UDPipe Flutter

NLP tokenization, POS tagging and dependency parsing using [UDPipe 1](https://ufal.mff.cuni.cz/udpipe/1) [UDPipe 1 github](https://github.com/ufal/udpipe), built with Flutter.

Native FFI on desktop and mobile. WebAssembly via [Emscripten](https://emscripten.org/) on the web.

## Platforms

| Platform | Status |
|----------|--------|
| Android  | ✅ |
| Web      | ✅ |
| Windows  | ✅ |
| Linux    | ✅ |
| macOS    | 🚧 Built but untested |
| iOS      | 🚧 Built but untested |

## Features

- Tokenization, lemmatization, POS tagging and dependency parsing
- Runs fully on-device (no server required)
- Separable verb detection for German
- 50+ pre-trained language models available from [ÚFAL](https://ufal.mff.cuni.cz/udpipe/1/models)
- Async batch processing keeps the UI thread free

## Live Demo

**[https://konyshevgmbh.github.io/udpipe_flutter/](https://konyshevgmbh.github.io/udpipe_flutter/)**


## pub.dev

**[https://pub.dev/packages/udpipe_flutter](https://pub.dev/packages/udpipe_flutter)**

## Getting Started

```bash
git clone --recursive https://github.com/konyshevgmbh/udpipe_flutter.git
flutter pub get
flutter run -d windows         # Windows desktop
flutter run -d linux           # Linux desktop
flutter run -d macos           # macOS desktop
flutter run                    # Android (device or emulator)
```

### Web (WASM)

Build the WebAssembly module first, then run on Chrome:

```bash
make run-web                   # builds WASM via Docker, then launches Chrome
```

Requires [Docker Desktop](https://www.docker.com/products/docker-desktop/).

### Model files

Download models from [ufal.mff.cuni.cz/udpipe/1/models](https://ufal.mff.cuni.cz/udpipe/1/models) and place them in `assets/models/`:

| Model ID | File | Size |
|----------|------|------|
| `gsd` | `german-gsd.udpipe` | ~20 MB |
| `hdt` | `german-hdt.udpipe` | ~60 MB |

## Library API

```dart
import 'package:udpipe_flutter/udpipe_flutter.dart';

final svc = UDPipeService();

// Load a model once per session
await svc.init(modelId: 'gsd');

// Process text (synchronous)
final result = svc.process('Er steigt aus dem Bus aus.');

for (final sentence in result.sentences) {
  for (final token in sentence.tokens) {
    // form → base form (lemma)  [POS tag]
    print('${token.form} → ${token.lemma}  [${token.upos}]');
    // Er → er  [PRON]
    // steigt → steigen  [VERB]
    // Bus → Bus  [NOUN]
  }
  for (final sv in sentence.sepVerbs) {
    print('sep.verb: ${sv.particle}+${sv.verbForm} → ${sv.fullLemma}');
    // sep.verb: aus+steigt → aussteigen
  }
}

// Async batch — runs in a background isolate
final results = await svc.processAllBlocksAsync(['Block one.', 'Block two.']);
```

## Architecture

```
lib/udpipe/
  udpipe_flutter.dart          — public API
  src/
    conllu_parser.dart         — CoNLL-U parser (pure Dart)
    udpipe_types.dart          — data classes and result builders
    udpipe_bindings.dart       — dart:ffi bindings
    udpipe_service.dart        — conditional export (native vs web)
    udpipe_service_native.dart — FFI service (Windows / Linux / macOS / Android)
    udpipe_service_web.dart    — WASM/JS service (web)

native/
  CMakeLists.txt               — builds udpipe_flutter.dll / .so / .dylib
  udpipe_ffi.cpp               — thin C wrapper around UDPipe
  udpipe_src/                  — git submodule: ufal/udpipe
  build_web.sh                 — Emscripten build script
```

## Tech Stack

| Component | Library |
|-----------|---------|
| UI | Flutter 3.x + Material 3 |
| Native bindings | [ffi](https://pub.dev/packages/ffi) |
| NLP engine | [UDPipe 1](https://github.com/ufal/udpipe) (C++, MPL 2.0) |
| Web engine | Emscripten WASM |

## License

Wrapper code — MIT  
UDPipe © ÚFAL MFF UK — [MPL 2.0](https://www.mozilla.org/en-US/MPL/2.0/)
