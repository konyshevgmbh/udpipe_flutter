# udpipe_flutter

Flutter demo app and reusable library for [UDPipe 1](https://ufal.mff.cuni.cz/udpipe/1) — tokenization, POS tagging and dependency parsing for 50+ languages.

**Platforms:** Windows · Linux · macOS · Android · iOS · Web (WASM)

---

## Demo app

Select a model, enter text, press **Analyze**. Tokens appear with UPOS tags and dependency relations; separated German verbs are detected and highlighted.

---

## Library API

The reusable code is in `lib/udpipe/`. Copy it into any Flutter project and add `ffi: ^2.1.0` to your `pubspec.yaml`.

```dart
import 'udpipe/udpipe_flutter.dart';

final svc = UDPipeService();

// Load a model (once per session)
await svc.init(modelId: 'gsd');   // 'gsd' | 'hdt'

// Watch loading state
svc.status.addListener(() { /* UDPipeStatus.loading / ready / error */ });

// Process text (synchronous, call on main isolate)
final result = svc.process('Er steigt aus dem Bus aus.');

for (final sentence in result.sentences) {
  for (final token in sentence.tokens) {
    print('${token.form}  ${token.upos}  ${token.lemma}');
  }
  for (final sv in sentence.sepVerbs) {
    print('sep.verb: ${sv.particle} + ${sv.verbForm} → ${sv.fullLemma}');
  }
}

// Async batch (runs in background isolate — keeps UI smooth)
final results = await svc.processAllBlocksAsync(['First block.', 'Second block.']);
```

### Key types

| Type | Description |
|------|-------------|
| `UDPipeService` | Singleton — load models, process text |
| `UDPipeStatus` | `idle` · `loading` · `ready` · `error` |
| `UDPipeResult` | List of `UDSentenceResult` |
| `UDSentenceResult` | `text`, `tokens`, `sepVerbs`, `byFormAll` |
| `UDToken` | `id`, `form`, `lemma`, `upos`, `deprel`, `head` |
| `SepVerb` | `fullLemma`, `verbForm`, `particle` |
| `kUdpipeModels` | Available model list |

---

## Setup

### 1. Clone with submodules

```bash
git clone --recursive https://github.com/konyshevgmbh/udpipe_flutter.git
# or after a plain clone:
git submodule update --init --recursive
```

The UDPipe C++ source lands in `native/udpipe_src/` (submodule → https://github.com/ufal/udpipe).

### 2. Download model files

Download from https://ufal.mff.cuni.cz/udpipe/1/models and place in `assets/models/`:

| Model ID | Expected filename |
|----------|-------------------|
| `gsd` | `german-gsd.udpipe` (~20 MB) |
| `hdt` | `german-hdt.udpipe` (~60 MB) |

### 3. Run

```bash
flutter pub get
flutter run -d windows   # linux / macos / chrome / android
```

### Web (WASM)

The web build requires pre-compiled WASM (`web/udpipe_ffi.wasm` + `web/udpipe_ffi.js`).  
Build with Emscripten or copy from the [Leser project](https://github.com/konyshevgmbh/leser).

```bash
cd native
emcmake cmake -B build_wasm
cmake --build build_wasm
cp build_wasm/udpipe_ffi.{js,wasm} ../web/
```

---

## Architecture

```
lib/udpipe/
  udpipe_flutter.dart          ← public API
  src/
    conllu_parser.dart         ← CoNLL-U parser (pure Dart)
    udpipe_types.dart          ← data classes + result builders
    udpipe_bindings.dart       ← dart:ffi bindings
    udpipe_service.dart        ← conditional export (native vs web)
    udpipe_service_native.dart ← FFI service (Windows/Linux/macOS/Android)
    udpipe_service_web.dart    ← WASM/JS service (web)

native/
  CMakeLists.txt               ← builds udpipe_flutter.{dll,so,dylib}
  udpipe_ffi.cpp               ← thin C wrapper
  udpipe_src/                  ← git submodule: ufal/udpipe
```

On Windows/Linux the DLL/SO is compiled by Flutter's CMake build and installed next to the executable.  
On Android the `.so` is compiled by Gradle's `externalNativeBuild` and bundled in the APK.  
On Web a pre-compiled WASM module is loaded at runtime via a JS bridge in `web/udpipe_init.js`.

---

## CI/CD

`.github/workflows/build.yml` builds all 6 platforms on every push to `main`.  
The web build is deployed to GitHub Pages automatically.

---

## License

UDPipe © ÚFAL MFF UK — [MPL 2.0](https://www.mozilla.org/en-US/MPL/2.0/)  
Wrapper code — MIT
