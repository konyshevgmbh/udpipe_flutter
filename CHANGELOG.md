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
