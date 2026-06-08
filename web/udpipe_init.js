// JS bridge between Dart (dart:js_interop) and the Emscripten UDPipe WASM module.
// Loaded synchronously so all window.udpipeWasm* functions are defined before Flutter runs.
// udpipe_ffi.js loads async; udpipeWasmInit polls for it (up to 30 s).

(function () {
  var _mod = null;

  window.udpipeWasmInit = function () {
    return new Promise(function (resolve, reject) {
      var waited = 0;
      var maxWait = 30000;
      var pollMs = 200;

      (function tryInit() {
        if (_mod !== null) return resolve();
        if (typeof createUDPipeModule === 'function') {
          createUDPipeModule()
            .then(function (m) { _mod = m; resolve(); })
            .catch(reject);
        } else if (waited >= maxWait) {
          reject(new Error('udpipe_ffi.js not available after ' + maxWait + 'ms'));
        } else {
          waited += pollMs;
          setTimeout(tryInit, pollMs);
        }
      })();
    });
  };

  window.udpipeWasmIsReady = function () { return _mod !== null; };

  // bytes: JS Uint8Array — returns WASM pointer (int32), 0 on failure.
  window.udpipeWasmLoadMemory = function (bytes) {
    if (!_mod) return 0;
    var ptr = _mod._malloc(bytes.length);
    _mod.HEAPU8.set(bytes, ptr);
    var handle = _mod._udpipe_load_memory(ptr, bytes.length);
    _mod._free(ptr);
    return handle;
  };

  // Returns CoNLL-U string or null on error.
  window.udpipeWasmProcess = function (handle, text) {
    if (!_mod || !handle) return null;
    var len = _mod.lengthBytesUTF8(text) + 1;
    var inPtr = _mod._malloc(len);
    _mod.stringToUTF8(text, inPtr, len);
    var outPtr = _mod._udpipe_process(handle, inPtr);
    _mod._free(inPtr);
    if (!outPtr) return null;
    var result = _mod.UTF8ToString(outPtr);
    _mod._udpipe_free_str(outPtr);
    return result;
  };

  window.udpipeWasmFree = function (handle) {
    if (_mod && handle) _mod._udpipe_free(handle);
  };
})();
