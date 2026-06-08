import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// ignore_for_file: non_constant_identifier_names

typedef _LoadNative    = Pointer Function(Pointer<Utf8>);
typedef _LoadDart      = Pointer Function(Pointer<Utf8>);

typedef _FreeNative    = Void Function(Pointer);
typedef _FreeDart      = void Function(Pointer);

typedef _ProcessNative = Pointer<Utf8> Function(Pointer, Pointer<Utf8>);
typedef _ProcessDart   = Pointer<Utf8> Function(Pointer, Pointer<Utf8>);

typedef _FreeStrNative = Void Function(Pointer<Utf8>);
typedef _FreeStrDart   = void Function(Pointer<Utf8>);

class UDPipeBindings {
  final DynamicLibrary _lib;

  late final _LoadDart    _load;
  late final _FreeDart    _free;
  late final _ProcessDart _process;
  late final _FreeStrDart _freeStr;

  UDPipeBindings(this._lib) {
    _load    = _lib.lookupFunction<_LoadNative,    _LoadDart>   ('udpipe_load');
    _free    = _lib.lookupFunction<_FreeNative,    _FreeDart>   ('udpipe_free');
    _process = _lib.lookupFunction<_ProcessNative, _ProcessDart>('udpipe_process');
    _freeStr = _lib.lookupFunction<_FreeStrNative, _FreeStrDart>('udpipe_free_str');
  }

  static UDPipeBindings? open() {
    try {
      final lib = _openLib();
      if (lib == null) return null;
      return UDPipeBindings(lib);
    } catch (_) {
      return null;
    }
  }

  static DynamicLibrary? _openLib() {
    if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final path = '$exeDir/udpipe_flutter.dll';
      if (File(path).existsSync()) return DynamicLibrary.open(path);
      return null;
    }
    if (Platform.isLinux) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final path = '$exeDir/lib/libudpipe_flutter.so';
      if (File(path).existsSync()) return DynamicLibrary.open(path);
      return null;
    }
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libudpipe_flutter.so');
    }
    if (Platform.isMacOS) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final path = '$exeDir/../Frameworks/libudpipe_flutter.dylib';
      if (File(path).existsSync()) return DynamicLibrary.open(path);
      return null;
    }
    return null;
  }

  Pointer load(String modelPath) {
    final pathPtr = modelPath.toNativeUtf8();
    try {
      return _load(pathPtr);
    } finally {
      malloc.free(pathPtr);
    }
  }

  void free(Pointer handle) => _free(handle);

  String? process(Pointer handle, String text) {
    final textPtr = text.toNativeUtf8();
    try {
      final outPtr = _process(handle, textPtr);
      if (outPtr == nullptr) return null;
      final result = outPtr.toDartString();
      _freeStr(outPtr);
      return result;
    } finally {
      malloc.free(textPtr);
    }
  }
}
