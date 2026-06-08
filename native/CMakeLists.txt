cmake_minimum_required(VERSION 3.14)
project(udpipe_flutter CXX)

# UDPipe source tree — git submodule at native/udpipe_src
# Clone with: git clone --recursive  OR  git submodule update --init
set(UDPIPE_SRC "${CMAKE_CURRENT_SOURCE_DIR}/udpipe_src/src")

file(GLOB_RECURSE UDPIPE_ALL_SOURCES "${UDPIPE_SRC}/*.cpp")
list(FILTER UDPIPE_ALL_SOURCES EXCLUDE REGEX ".*/udpipe\\.cpp$")
list(FILTER UDPIPE_ALL_SOURCES EXCLUDE REGEX ".*/win_wmain_utf8\\.cpp$")
list(FILTER UDPIPE_ALL_SOURCES EXCLUDE REGEX ".*/rest_server/.*")

add_library(udpipe_ffi SHARED
  "${CMAKE_CURRENT_SOURCE_DIR}/udpipe_ffi.cpp"
  ${UDPIPE_ALL_SOURCES}
)

# Keep the output filename as udpipe_flutter.dll/.so/.dylib so Dart FFI can
# find it without changes to the Dart code.
set_target_properties(udpipe_ffi PROPERTIES OUTPUT_NAME "udpipe_flutter")

target_include_directories(udpipe_ffi PRIVATE
  "${UDPIPE_SRC}"
  "${CMAKE_CURRENT_SOURCE_DIR}/udpipe_src/src_lib_only"
)

target_compile_features(udpipe_ffi PRIVATE cxx_std_11)

if(MSVC)
  target_compile_options(udpipe_ffi PRIVATE
    /EHsc /utf-8
    /wd4100 /wd4127 /wd4244 /wd4245 /wd4267 /wd4305 /wd4458 /wd4996
  )
  target_compile_definitions(udpipe_ffi PRIVATE _HAS_EXCEPTIONS=1)
  set_target_properties(udpipe_ffi PROPERTIES
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
  )
elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  target_compile_options(udpipe_ffi PRIVATE
    -fvisibility=hidden -fPIC -fexceptions -frtti
    -Wno-unused-parameter -Wno-sign-compare -Wno-deprecated-declarations
  )
endif()

if(ANDROID)
  target_link_libraries(udpipe_ffi PRIVATE log)
endif()
