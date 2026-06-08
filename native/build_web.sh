#!/usr/bin/env bash
# Build UDPipe to WebAssembly using Emscripten.
# Output: web/udpipe_ffi.js + web/udpipe_ffi.wasm
#
# Requirements: emsdk activated (emcc in PATH)
#   https://emscripten.org/docs/getting_started/downloads.html
#   source ~/emsdk/emsdk_env.sh
#
# Usage:
#   cd <repo-root>
#   bash native/build_web.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$SCRIPT_DIR/udpipe_src/src"
OUT_DIR="$REPO_DIR/web"

if ! command -v em++ &>/dev/null; then
  echo "ERROR: em++ not found. Activate emsdk first:" >&2
  echo "  source ~/emsdk/emsdk_env.sh" >&2
  exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR: UDPipe sources not found at $SRC_DIR" >&2
  echo "  Run: git submodule update --init --recursive" >&2
  exit 1
fi

# Collect all UDPipe .cpp sources (same exclusions as CMakeLists.txt)
mapfile -d '' SOURCES < <(find "$SRC_DIR" -name "*.cpp" \
  ! -path "*/udpipe.cpp" \
  ! -path "*/win_wmain_utf8.cpp" \
  ! -path "*/rest_server/*" \
  -print0)
SOURCES+=("$SCRIPT_DIR/udpipe_ffi.cpp")

echo "Building UDPipe WASM (${#SOURCES[@]} source files)..."

em++ -O2 \
  -std=c++17 \
  -I"$SRC_DIR" \
  -I"$SCRIPT_DIR/udpipe_src/src_lib_only" \
  -fexceptions \
  "${SOURCES[@]}" \
  -sEXPORTED_FUNCTIONS='["_udpipe_load_memory","_udpipe_process","_udpipe_free","_udpipe_free_str","_malloc","_free"]' \
  -sEXPORTED_RUNTIME_METHODS='["UTF8ToString","stringToUTF8","lengthBytesUTF8","HEAPU8"]' \
  -sALLOW_MEMORY_GROWTH=1 \
  -sINITIAL_MEMORY=67108864 \
  -sMODULARIZE=1 \
  -sEXPORT_NAME=createUDPipeModule \
  -sENVIRONMENT=web \
  -o "$OUT_DIR/udpipe_ffi.js"

echo "Done: $OUT_DIR/udpipe_ffi.js + $OUT_DIR/udpipe_ffi.wasm"
