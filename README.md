# D&D Scene Generator

A cross-platform application that listens to spoken tabletop RPG narration, detects place descriptions, and generates images of those scenes locally using AI -- entirely offline.

## Platforms

- Windows
- Linux
- Android
- iOS

## How It Works

1. **Listen** -- The app records audio from the microphone and transcribes speech to text using whisper.cpp
2. **Analyze** -- A local LLM (via llama.cpp) periodically analyzes the transcribed text to detect place/scene descriptions
3. **Generate** -- When a new place is detected, stable-diffusion.cpp generates an image combining the scene description, your base style settings, and any active character descriptions
4. **Repeat** -- The app continues listening. When a different place is described, it generates a new scene image

## Features

- **Fully offline** -- All AI processing runs on-device. No cloud services required.
- **Model selection** -- Choose from multiple model sizes for each AI component (speech, NLP, image generation). Smaller models run faster on mobile; larger models produce better results on desktop.
- **Style presets** -- Fantasy Oil Painting, Dark Gothic, Watercolor, Anime, Realistic, Pixel Art, or define your own style.
- **Character system** -- Define characters with text descriptions and optional reference images. Characters are injected into every generated scene.
- **PhotoMaker** -- When using SDXL models, provide 1-4 reference photos per character for consistent likeness across scenes.
- **Gallery** -- All generated scenes are saved with their prompts for later review.
- **Responsive UI** -- Adaptive layout works on phones, tablets, and desktop windows.

## Architecture

```
Microphone → whisper.cpp (STT) → Text Buffer → llama.cpp (NLP)
    → Place detected → Prompt Builder → stable-diffusion.cpp → Scene Image
```

### AI Components

| Component | Library | Purpose |
|-----------|---------|---------|
| Speech-to-Text | whisper.cpp | Transcribes audio to text |
| NLP | llama.cpp | Detects place descriptions, crafts prompts |
| Image Generation | stable-diffusion.cpp | Generates scene images from prompts |
| Character Injection | PhotoMaker (via sd.cpp) | Injects character likenesses (SDXL only) |

### Available Models

| Component | Small (fast) | Medium | Large (quality) |
|-----------|-------------|--------|-----------------|
| Whisper | Tiny (~75MB) | Base (~150MB) | Small (~500MB) |
| LLM | Qwen2 0.5B (~400MB) | Phi-3 Mini (~2.3GB) | Llama 3.2 3B (~2GB) |
| Image Gen | SD 1.5 Q4 (~1GB) | SDXL Q4 (~3.5GB) | SDXL Q8 (~6.5GB) |

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.10+
- For native library compilation: CMake 3.14+, C/C++ toolchain

### Setup

```bash
# Clone the repository
git clone <repo-url>
cd dnd

# Install dependencies
flutter pub get

# Run on your platform
flutter run -d windows
flutter run -d linux
flutter run -d android
flutter run -d ios
```

### Building Native Libraries

The app requires compiled native libraries for stable-diffusion.cpp. These are built per-platform:

```bash
cd native

# Clone stable-diffusion.cpp
git clone --recurse-submodules https://github.com/leejet/stable-diffusion.cpp

# Build (example for Linux/macOS)
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# Place the resulting library in the appropriate platform directory:
#   Windows: windows/runner/sd_native.dll
#   Linux:   linux/lib/libsd_native.so
#   Android: android/app/src/main/jniLibs/<abi>/libsd_native.so
#   iOS:     (statically linked via Xcode)
```

For whisper.cpp and llama.cpp, the app uses existing Flutter packages (`whisper_ggml` and `llamadart`) that handle native compilation automatically.

### First Run

1. Open the **Models** tab
2. Download at least one model from each category (Speech, NLP, Image Gen)
3. Activate the downloaded models
4. Open the **Session** tab and tap **Start Session**
5. Start narrating your D&D session!

## Project Structure

```
lib/
  main.dart                          # App entry point
  app.dart                           # MaterialApp with theme and routing
  core/
    theme.dart                       # Dark fantasy theme
    router.dart                      # GoRouter navigation
    models/                          # Data classes
      character.dart
      scene_image.dart
      model_info.dart
      generation_settings.dart
    services/                        # Business logic
      audio_service.dart             # Microphone recording
      stt_service.dart               # whisper.cpp speech-to-text
      nlp_service.dart               # llama.cpp place detection
      image_gen_service.dart         # stable-diffusion.cpp generation
      prompt_builder.dart            # Combines style + place + characters
      session_controller.dart        # Orchestrates the full pipeline
      model_manager.dart             # Model download and management
      storage_service.dart           # Hive-backed persistence
      permission_service.dart        # Platform permissions
    providers/                       # Riverpod state management
      providers.dart
    native/                          # FFI bindings
      sd_ffi.dart                    # Dart FFI for sd_wrapper
  features/
    session/                         # Main listening + scene display
    characters/                      # Character CRUD + image upload
    model_management/                # Model download/activate/delete
    settings/                        # Style parameters and presets
    gallery/                         # Scene image history
native/
  src/
    sd_wrapper.h                     # C API for stable-diffusion.cpp
    sd_wrapper.c                     # Implementation / stubs
  CMakeLists.txt                     # Cross-platform build
```

## Platform Notes

- **Android**: Vulkan GPU acceleration where available. Minimum 4GB RAM for SD 1.5; 8GB+ for SDXL. Uses `RECORD_AUDIO` permission.
- **iOS**: Metal GPU acceleration. CoreML for Whisper. 4GB+ RAM. Requires microphone permission.
- **Windows/Linux**: CPU + optional GPU (CUDA/Vulkan). Can handle larger models comfortably.
- **Mobile performance**: Image generation on phones takes 1-5 minutes per image depending on model and resolution. Use SD 1.5 at 256x256 or 512x512 for faster results.

## License

MIT
