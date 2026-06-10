import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'udpipe_types.dart';

// JS bridge (defined in web/udpipe_init.js)

@JS('udpipeWasmInit')
external JSPromise<JSAny?> _jsInit();

@JS('udpipeWasmIsReady')
external JSBoolean _jsIsReady();

@JS('udpipeWasmLoadMemory')
external JSNumber _jsLoadMemory(JSUint8Array bytes);

@JS('udpipeWasmProcess')
external JSString? _jsProcess(JSNumber handle, JSString text);

@JS('udpipeWasmFree')
external void _jsFree(JSNumber handle);

/// Singleton service that wraps the UDPipe WASM module via JS interop.
///
/// The WASM module (`web/udpipe_ffi.wasm`) must be built with Emscripten
/// before running the web target. See `make wasm` or `build_wasm.ps1`.
class UDPipeService {
  UDPipeService._();
  static final UDPipeService _instance = UDPipeService._();
  factory UDPipeService() => _instance;

  double _handle = 0;
  String? _loadedModel;
  Future<void> _initFuture = Future.value();

  /// Current loading state. Listen to this notifier to react to state changes.
  final ValueNotifier<UDPipeStatus> status = ValueNotifier(UDPipeStatus.idle);

  /// Human-readable error message when [status] is [UDPipeStatus.error].
  String? loadError;

  /// Whether a model is loaded and [process] can be called.
  bool get isAvailable => _handle != 0;

  /// Completes when the current [init] call finishes (or immediately if idle).
  Future<void> get whenReady => _initFuture;

  /// Loads the model identified by [modelId] (one of [kUdpipeModels]).
  /// Returns immediately if the requested model is already loaded.
  Future<void> init({String modelId = 'hdt'}) {
    if (_loadedModel == modelId && isAvailable) return Future.value();
    _initFuture = _load(modelId);
    return _initFuture;
  }

  Future<void> _load(String modelId) async {
    if (isAvailable) dispose();
    loadError = null;
    status.value = UDPipeStatus.loading;

    try {
      if (!_jsIsReady().toDart) {
        await _jsInit().toDart;
      }
    } catch (e) {
      loadError = 'WASM init failed: $e';
      status.value = UDPipeStatus.error;
      return;
    }

    final info = udpipeModelById(modelId);
    final ByteData data;
    try {
      data = await rootBundle.load('assets/models/${info.fileName}');
    } catch (e) {
      loadError = 'Model asset not found: $e';
      status.value = UDPipeStatus.error;
      return;
    }

    final h = _jsLoadMemory(data.buffer.asUint8List().toJS).toDartDouble.toInt();
    if (h == 0) {
      loadError = 'udpipe_load_memory returned 0.';
      status.value = UDPipeStatus.error;
      return;
    }

    _handle = h.toDouble();
    _loadedModel = modelId;
    status.value = UDPipeStatus.ready;
  }

  /// Runs UDPipe on [text] and returns the parsed result.
  UDPipeResult process(String text) {
    if (!isAvailable) return UDPipeResult.empty;
    final conllu = _jsProcess(_handle.toJS, text.toJS)?.toDart;
    if (conllu == null || conllu.isEmpty) return UDPipeResult.empty;
    return buildUDPipeResult(conllu);
  }

  /// Processes [blocks] synchronously, returning one [UDPipeResult] per block.
  List<UDPipeResult> processBatchPerBlock(List<String> blocks) {
    if (!isAvailable) return List.filled(blocks.length, UDPipeResult.empty);
    final conllu = _jsProcess(_handle.toJS, blocks.join('\n\n').toJS)?.toDart;
    if (conllu == null || conllu.isEmpty) return List.filled(blocks.length, UDPipeResult.empty);
    return splitUDPipeResultByBlocks(conllu, blocks);
  }

  /// Processes [blocks] in micro-task batches to keep the UI responsive.
  Future<List<UDPipeResult>> processAllBlocksAsync(List<String> blocks) async {
    if (!isAvailable) return List.filled(blocks.length, UDPipeResult.empty);
    const kBatch = 5;
    final all = List<UDPipeResult>.filled(blocks.length, UDPipeResult.empty);
    for (var i = 0; i < blocks.length; i += kBatch) {
      await Future.delayed(Duration.zero);
      final end = (i + kBatch).clamp(0, blocks.length);
      final partial = processBatchPerBlock(blocks.sublist(i, end));
      for (var j = 0; j < partial.length; j++) {
        all[i + j] = partial[j];
      }
    }
    return all;
  }

  /// Frees the WASM model handle. Call before loading a different model.
  void dispose() {
    if (_handle != 0) {
      _jsFree(_handle.toJS);
      _handle = 0;
      _loadedModel = null;
    }
  }
}
