WASM_OUT  := web/udpipe_ffi.wasm
WASM_SRCS := native/udpipe_ffi.cpp \
             $(shell find native/udpipe_src/src -name "*.cpp" -o -name "*.h" 2>/dev/null)

EXAMPLE_WASM := example/web/udpipe_ffi.wasm

.PHONY: wasm run-web serve-web run-windows help

# ── Targets ────────────────────────────────────────────────────────────────

$(WASM_OUT): $(WASM_SRCS)
	docker run --rm -v "$(CURDIR):/src" -w /src emscripten/emsdk bash native/build_web.sh

wasm: $(WASM_OUT)  ## Build web/udpipe_ffi.wasm via Docker (skips if up to date)

# Copy generated WASM files into the example app (udpipe_init.js is committed)
$(EXAMPLE_WASM): $(WASM_OUT)
	cp web/udpipe_ffi.js web/udpipe_ffi.wasm example/web/

run-web: $(EXAMPLE_WASM)  ## Build WASM if needed, sync to example, launch on Chrome
	cd example && flutter run -d chrome

serve-web: $(EXAMPLE_WASM)  ## Build WASM if needed, sync to example, serve on :8080
	cd example && flutter build web
	cd example/build/web && python -m http.server 8080

run-windows:  ## Launch on Windows desktop
	cd example && flutter run -d windows

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS=":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'
