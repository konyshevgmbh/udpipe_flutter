import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' hide Size;
import 'udpipe_bindings.dart';
import 'udpipe_types.dart';

/// Singleton service that wraps the UDPipe native library via dart:ffi.
///
/// Usage:
/// ```dart
/// final svc = UDPipeService();
/// await svc.init(modelId: 'gsd');
/// final result = svc.process('Er steigt aus dem Bus aus.');
/// ```
class UDPipeService {
  UDPipeService._();
  static final UDPipeService _instance = UDPipeService._();
  factory UDPipeService() => _instance;

  UDPipeBindings? _bindings;
  Pointer?        _handle;
  String?         _loadedModel;
  Future<void>    _initFuture = Future.value();

  /// Current loading state. Listen to this notifier to react to state changes.
  final ValueNotifier<UDPipeStatus> status = ValueNotifier(UDPipeStatus.idle);

  /// Human-readable error message when [status] is [UDPipeStatus.error].
  String? loadError;

  /// Whether a model is loaded and [process] can be called.
  bool get isAvailable => _handle != null && _handle != nullptr;

  /// Completes when the current [init] call finishes (or immediately if idle).
  Future<void> get whenReady => _initFuture;

  /// Loads the model identified by [modelId] (one of [kUdpipeModels]).
  /// Returns immediately if the requested model is already loaded.
  Future<void> init({String modelId = 'german-gsd'}) {
    if (_loadedModel == modelId && isAvailable) return Future.value();
    _initFuture = _load(modelId);
    return _initFuture;
  }

  /// Loads a model from an arbitrary Flutter asset path.
  ///
  /// Example: `await svc.initFromAsset('assets/models/russian-syntagrus.udpipe')`
  ///
  /// Returns immediately if [assetPath] is already loaded.
  Future<void> initFromAsset(String assetPath) {
    if (_loadedModel == assetPath && isAvailable) return Future.value();
    _initFuture = _loadFromAsset(assetPath);
    return _initFuture;
  }

  /// Loads a model directly from [bytes] (e.g. downloaded at runtime).
  ///
  /// Always reloads — no caching by content.
  Future<void> initFromBytes(Uint8List bytes) {
    _initFuture = _loadFromBytesImpl(bytes, cacheKey: null);
    return _initFuture;
  }

  Future<void> _load(String modelId) async {
    final dllPath = await _prepareNative();
    if (dllPath == null) return;

    final info = udpipeModelById(modelId);

    int? address;
    if (Platform.isAndroid) {
      final data = await rootBundle.load('assets/models/${info.fileName}');
      final transferable = TransferableTypedData.fromList([data.buffer.asUint8List()]);
      address = await Isolate.run(() {
        final bytes = transferable.materialize().asUint8List();
        return _loadModelFromMemoryInIsolate(dllPath, bytes);
      });
    } else {
      final modelPath = _resolveModelPath(info.fileName);
      if (modelPath == null || !File(modelPath).existsSync()) {
        loadError = 'Model file not found: $modelPath\n'
            'Download models from https://ufal.mff.cuni.cz/udpipe/1/models '
            'and place them in the app\'s assets/models/ folder.';
        status.value = UDPipeStatus.error;
        return;
      }
      address = await Isolate.run(() => _loadModelInIsolate(dllPath, modelPath));
    }

    _finalise(address, cacheKey: modelId);
  }

  Future<void> _loadFromAsset(String assetPath) async {
    final dllPath = await _prepareNative();
    if (dllPath == null) return;

    int? address;
    if (Platform.isAndroid) {
      final ByteData data;
      try {
        data = await rootBundle.load(assetPath);
      } catch (_) {
        loadError = 'Asset not found: $assetPath';
        status.value = UDPipeStatus.error;
        return;
      }
      final transferable = TransferableTypedData.fromList([data.buffer.asUint8List()]);
      address = await Isolate.run(() {
        final bytes = transferable.materialize().asUint8List();
        return _loadModelFromMemoryInIsolate(dllPath, bytes);
      });
    } else {
      final filePath = _resolveAssetPath(assetPath);
      if (filePath == null || !File(filePath).existsSync()) {
        loadError = 'Asset file not found: $assetPath';
        status.value = UDPipeStatus.error;
        return;
      }
      address = await Isolate.run(() => _loadModelInIsolate(dllPath, filePath));
    }

    _finalise(address, cacheKey: assetPath);
  }

  Future<void> _loadFromBytesImpl(Uint8List bytes, {required String? cacheKey}) async {
    final dllPath = await _prepareNative();
    if (dllPath == null) return;

    final transferable = TransferableTypedData.fromList([bytes]);
    final address = await Isolate.run(() {
      final b = transferable.materialize().asUint8List();
      return _loadModelFromMemoryInIsolate(dllPath, b);
    });
    _finalise(address, cacheKey: cacheKey);
  }

  /// Resets state, checks bindings and dll. Returns dll path or null on error.
  Future<String?> _prepareNative() async {
    if (isAvailable) dispose();
    loadError = null;
    status.value = UDPipeStatus.loading;

    _bindings ??= UDPipeBindings.open();
    if (_bindings == null) {
      loadError = 'Native library not available on this platform.';
      status.value = UDPipeStatus.error;
      return null;
    }

    final dllPath = _resolveDllPath();
    if (dllPath == null) {
      loadError = 'Platform not supported.';
      status.value = UDPipeStatus.error;
      return null;
    }
    return dllPath;
  }

  void _finalise(int? address, {required String? cacheKey}) {
    if (address == null || address == 0) {
      loadError = 'Failed to load model.';
      status.value = UDPipeStatus.error;
      return;
    }
    _handle = Pointer.fromAddress(address);
    _loadedModel = cacheKey;
    status.value = UDPipeStatus.ready;
  }

  /// Runs UDPipe on [text] and returns the parsed result.
  ///
  /// Synchronous — runs on the calling isolate. For large batches prefer
  /// [processAllBlocksAsync].
  UDPipeResult process(String text) {
    if (!isAvailable) return UDPipeResult.empty;
    final conllu = _bindings!.process(_handle!, text);
    if (conllu == null || conllu.isEmpty) return UDPipeResult.empty;
    return buildUDPipeResult(conllu);
  }

  /// Processes [blocks] synchronously, returning one [UDPipeResult] per block.
  List<UDPipeResult> processBatchPerBlock(List<String> blocks) {
    if (!isAvailable) return List.filled(blocks.length, UDPipeResult.empty);
    final conllu = _bindings!.process(_handle!, blocks.join('\n\n'));
    if (conllu == null || conllu.isEmpty) return List.filled(blocks.length, UDPipeResult.empty);
    return splitUDPipeResultByBlocks(conllu, blocks);
  }

  /// Processes [blocks] in a background isolate, yielding one [UDPipeResult]
  /// per block. Keeps the UI thread free for large inputs.
  Future<List<UDPipeResult>> processAllBlocksAsync(List<String> blocks) async {
    if (!isAvailable) return List.filled(blocks.length, UDPipeResult.empty);
    if (kIsWeb) return processBatchPerBlock(blocks);
    final dllPath = _resolveDllPath();
    if (dllPath == null) return List.filled(blocks.length, UDPipeResult.empty);
    final handleAddr = _handle!.address;
    return Isolate.run(() => _processAllBlocksInIsolate(dllPath, handleAddr, blocks));
  }

  /// Frees the native model handle. Call before loading a different model.
  void dispose() {
    if (_handle != null && _handle != nullptr) {
      _bindings?.free(_handle!);
    }
    _handle = null;
    _loadedModel = null;
  }

  static String? _resolveModelPath(String fileName) =>
      _resolveAssetPath('assets/models/$fileName');

  static String? _resolveAssetPath(String assetPath) {
    if (Platform.isWindows || Platform.isLinux) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return '$exeDir/data/flutter_assets/$assetPath';
    }
    if (Platform.isMacOS) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return '$exeDir/../Resources/flutter_assets/$assetPath';
    }
    return null;
  }

  static String? _resolveDllPath() {
    if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return '$exeDir/udpipe_flutter.dll';
    }
    if (Platform.isLinux) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return '$exeDir/lib/libudpipe_flutter.so';
    }
    if (Platform.isAndroid) return 'libudpipe_flutter.so';
    if (Platform.isMacOS) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return '$exeDir/../Frameworks/libudpipe_flutter.dylib';
    }
    return null;
  }
}

int? _loadModelInIsolate(String dllPath, String modelPath) {
  try {
    final lib = DynamicLibrary.open(dllPath);
    final loadFn = lib.lookupFunction<
      Pointer Function(Pointer<Utf8>),
      Pointer Function(Pointer<Utf8>)
    >('udpipe_load');
    final pathPtr = modelPath.toNativeUtf8();
    final handle = loadFn(pathPtr);
    malloc.free(pathPtr);
    if (handle == nullptr) return null;
    return handle.address;
  } catch (_) {
    return null;
  }
}

int? _loadModelFromMemoryInIsolate(String dllPath, Uint8List bytes) {
  try {
    final lib = DynamicLibrary.open(dllPath);
    final loadFn = lib.lookupFunction<
      Pointer Function(Pointer<Uint8>, Size),
      Pointer Function(Pointer<Uint8>, int)
    >('udpipe_load_memory');
    final ptr = malloc<Uint8>(bytes.length);
    ptr.asTypedList(bytes.length).setAll(0, bytes);
    final handle = loadFn(ptr, bytes.length);
    malloc.free(ptr);
    if (handle == nullptr) return null;
    return handle.address;
  } catch (_) {
    return null;
  }
}

List<UDPipeResult> _processAllBlocksInIsolate(
    String dllPath, int handleAddr, List<String> blocks) {
  try {
    final lib = DynamicLibrary.open(dllPath);
    final processFn = lib.lookupFunction<
        Pointer<Utf8> Function(Pointer, Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer, Pointer<Utf8>)>('udpipe_process');
    final freeStrFn = lib.lookupFunction<
        Void Function(Pointer<Utf8>),
        void Function(Pointer<Utf8>)>('udpipe_free_str');

    final handle = Pointer.fromAddress(handleAddr);
    final textPtr = blocks.join('\n\n').toNativeUtf8();
    final outPtr = processFn(handle, textPtr);
    malloc.free(textPtr);

    if (outPtr == nullptr) return List.filled(blocks.length, UDPipeResult.empty);
    final conllu = outPtr.toDartString();
    freeStrFn(outPtr);
    return splitUDPipeResultByBlocks(conllu, blocks);
  } catch (_) {
    return List.filled(blocks.length, UDPipeResult.empty);
  }
}
