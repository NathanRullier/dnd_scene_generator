cmake_minimum_required(VERSION 3.14)
project(sd_native LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Build as shared library for FFI
add_library(sd_native SHARED
    src/sd_wrapper.c
)

target_include_directories(sd_native PUBLIC src)

# Platform-specific settings
if(WIN32)
    target_compile_definitions(sd_native PRIVATE _CRT_SECURE_NO_WARNINGS)
endif()

# When stable-diffusion.cpp is added as a submodule, uncomment:
#
# add_subdirectory(stable-diffusion.cpp)
# target_link_libraries(sd_native PRIVATE stable-diffusion)
# target_include_directories(sd_native PRIVATE stable-diffusion.cpp)
#
# For GPU acceleration:
#   - Windows/Linux: Enable Vulkan or CUDA backends
#   - macOS/iOS: Metal is used automatically
#   - Android: Vulkan via NDK

# Installation
install(TARGETS sd_native
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)
