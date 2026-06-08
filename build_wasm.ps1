# Build UDPipe WASM via Docker (emscripten/emsdk image).
# Output: web/udpipe_ffi.js + web/udpipe_ffi.wasm
#
# Usage:
#   .\build_wasm.ps1
#
# Requirements: Docker Desktop running

$ErrorActionPreference = 'Stop'

$repoDir = $PSScriptRoot
$repoWin = $repoDir.Replace('\', '/')

Write-Host "Building UDPipe WASM via Docker..." -ForegroundColor Cyan

docker run --rm `
  -v "${repoWin}:/src" `
  -w /src `
  emscripten/emsdk `
  bash native/build_web.sh

if ($LASTEXITCODE -ne 0) {
  Write-Error "Docker build failed (exit $LASTEXITCODE)"
  exit $LASTEXITCODE
}

Write-Host "Done: web/udpipe_ffi.js + web/udpipe_ffi.wasm" -ForegroundColor Green
