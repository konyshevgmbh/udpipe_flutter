WASM_OUT := web/udpipe_ffi.wasm
WASM_SRCS := native/udpipe_ffi.cpp \
             $(shell find native/udpipe_src/src -name "*.cpp" -o -name "*.h" 2>/dev/null)

.PHONY: wasm run-web run-windows help

# ── Targets ────────────────────────────────────────────────────────────────

$(WASM_OUT): $(WASM_SRCS)
	docker run --rm -v "$(CURDIR):/src" -w /src emscripten/emsdk bash native/build_web.sh

wasm: $(WASM_OUT)  ## Build web/udpipe_ffi.wasm via Docker (skips if up to date)

run-web: $(WASM_OUT)  ## Build WASM if needed, then launch on Chrome
	flutter run -d chrome

run-windows:  ## Launch on Windows desktop
	flutter run -d windows

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS=":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'
