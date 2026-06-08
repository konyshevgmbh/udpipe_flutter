// Thin C wrapper over UDPipe 1 C++ API for dart:ffi.
// One opaque handle = (model* + pipeline*).
// All strings are UTF-8. Caller frees output with udpipe_free_str().

#include <cstring>
#include <sstream>
#include <string>

#include "udpipe.h"

using namespace ufal::udpipe;

#if defined(_WIN32) || defined(_WIN64)
  #define UDPIPE_EXPORT extern "C" __declspec(dllexport)
#else
  #define UDPIPE_EXPORT extern "C" __attribute__((visibility("default")))
#endif

struct UDPipeHandle {
  model*    m;
  pipeline* p;
};

// Load model from memory buffer. Returns nullptr on failure.
UDPIPE_EXPORT void* udpipe_load_memory(const uint8_t* data, size_t len) {
  struct MemBuf : std::streambuf {
    MemBuf(const uint8_t* d, size_t n) {
      char* p = const_cast<char*>(reinterpret_cast<const char*>(d));
      setg(p, p, p + n);
    }
  } buf(data, len);
  std::istream is(&buf);
  model* m = model::load(is);
  if (!m) return nullptr;
  pipeline* p = new pipeline(m,
    "tokenize", pipeline::DEFAULT, pipeline::DEFAULT, "conllu");
  return new UDPipeHandle{m, p};
}

// Load model from file path. Returns nullptr on failure.
UDPIPE_EXPORT void* udpipe_load(const char* model_path) {
  model* m = model::load(model_path);
  if (!m) return nullptr;
  pipeline* p = new pipeline(m,
    "tokenize", pipeline::DEFAULT, pipeline::DEFAULT, "conllu");
  return new UDPipeHandle{m, p};
}

// Free model and pipeline.
UDPIPE_EXPORT void udpipe_free(void* handle) {
  if (!handle) return;
  auto* h = static_cast<UDPipeHandle*>(handle);
  delete h->p;
  delete h->m;
  delete h;
}

// Process UTF-8 text. Returns malloc'd CoNLL-U string; free with udpipe_free_str().
UDPIPE_EXPORT char* udpipe_process(void* handle, const char* text) {
  if (!handle || !text) return nullptr;
  auto* h = static_cast<UDPipeHandle*>(handle);
  std::istringstream is(text);
  std::ostringstream os;
  std::string error;
  if (!h->p->process(is, os, error)) return nullptr;
  const std::string result = os.str();
  char* out = new char[result.size() + 1];
  std::memcpy(out, result.c_str(), result.size() + 1);
  return out;
}

// Free a string returned by udpipe_process().
UDPIPE_EXPORT void udpipe_free_str(char* s) {
  delete[] s;
}

// Returns version string (static, no need to free).
UDPIPE_EXPORT const char* udpipe_version() {
  return "udpipe-flutter-1";
}
