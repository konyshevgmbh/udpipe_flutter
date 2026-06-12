## 0.2.0

* Expanded model catalog: `kUdpipeModels` now lists all ~94 UDPipe 1 (UD 2.5) models across 60+
  languages, not just the two German models.
* Added `UDPipeService.initFromAsset(String assetPath)` — load any `.udpipe` file from the Flutter
  asset bundle by path (not limited to `assets/models/`).
* Added `UDPipeService.initFromBytes(Uint8List bytes)` — load a model from raw bytes, e.g. after
  downloading it at runtime.
* **Breaking:** `UDPipeModelInfo.id` is now the full treebank name (e.g. `'german-gsd'` instead of
  `'gsd'`). Legacy short ids `'gsd'` and `'hdt'` are still accepted by `udpipeModelById` and
  `UDPipeService.init` for backward compatibility.
* **Breaking:** `UDPipeModelInfo.size` field removed.
* `UDPipeModelInfo.fileName` is now a computed getter (`'$id.udpipe'`) instead of a stored field.
* Default `modelId` in `UDPipeService.init` changed from `'hdt'` to `'german-gsd'`.

## 0.1.3

* Fixed pub.dev documentation score: resolved dartdoc library-name conflict,
  excluded demo-app files from public API, added missing dartdoc comments.
* Fixed pub.dev static analysis score: added `assets/models/README.md`
  so the declared asset directory exists in the published package.
* `assets/models/README.md` documents where to download UDPipe model files.

## 0.1.1

* Added `gender`, `number`, and `degree` fields to `UDToken` (parsed from the CoNLL-U FEATS column).
* Added package example (`example/example.dart`).

## 0.1.0+1

* Initial release.
* Native FFI bindings for UDPipe 1 on Windows, Linux, macOS, Android.
* WebAssembly backend via Emscripten for Flutter web.
* CoNLL-U parser with separable-verb detection (German).
* Demo app with model selector, token table and UPOS colour badges.
