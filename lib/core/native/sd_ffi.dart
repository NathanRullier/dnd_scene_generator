import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

// --- FFI Type definitions matching sd_wrapper.h ---

typedef SdContextT = Pointer<Void>;

final class SdGenerationParams extends Struct {
  @Int32()
  external int width;

  @Int32()
  external int height;

  @Int32()
  external int steps;

  @Float()
  external double cfgScale;

  @Int64()
  external int seed;

  @Int32()
  external int sampleMethod;

  @Int32()
  external int schedule;

  @Int32()
  external int batchCount;

  @Int32()
  external int clipSkip;
}

final class SdImageT extends Struct {
  external Pointer<Uint8> data;

  @Int32()
  external int width;

  @Int32()
  external int height;

  @Int32()
  external int channels;
}

typedef SdProgressCallbackNative = Void Function(
    Int32 step, Int32 totalSteps, Pointer<Void> userdata);
typedef SdProgressCallback = void Function(
    int step, int totalSteps, Pointer<Void> userdata);

// --- Native function signatures ---

typedef SdInitNative = Pointer<Void> Function(
    Pointer<Utf8> modelPath, Pointer<Utf8> vaePath, Int32 nThreads);
typedef SdInitDart = Pointer<Void> Function(
    Pointer<Utf8> modelPath, Pointer<Utf8> vaePath, int nThreads);

typedef SdSetPhotomakerNative = Bool Function(
    Pointer<Void> ctx, Pointer<Utf8> photomakerPath);
typedef SdSetPhotomakerDart = bool Function(
    Pointer<Void> ctx, Pointer<Utf8> photomakerPath);

typedef SdSetReferenceImagesNative = Bool Function(
    Pointer<Void> ctx, Pointer<Pointer<Utf8>> imagePaths, Int32 numImages);
typedef SdSetReferenceImagesDart = bool Function(
    Pointer<Void> ctx, Pointer<Pointer<Utf8>> imagePaths, int numImages);

typedef SdTxt2imgNative = Pointer<SdImageT> Function(
    Pointer<Void> ctx,
    Pointer<Utf8> prompt,
    Pointer<Utf8> negativePrompt,
    SdGenerationParams params,
    Pointer<NativeFunction<SdProgressCallbackNative>> progressCb,
    Pointer<Void> userdata);
typedef SdTxt2imgDart = Pointer<SdImageT> Function(
    Pointer<Void> ctx,
    Pointer<Utf8> prompt,
    Pointer<Utf8> negativePrompt,
    SdGenerationParams params,
    Pointer<NativeFunction<SdProgressCallbackNative>> progressCb,
    Pointer<Void> userdata);

typedef SdSaveImageNative = Bool Function(
    Pointer<SdImageT> image, Pointer<Utf8> outputPath);
typedef SdSaveImageDart = bool Function(
    Pointer<SdImageT> image, Pointer<Utf8> outputPath);

typedef SdFreeImageNative = Void Function(Pointer<SdImageT> image);
typedef SdFreeImageDart = void Function(Pointer<SdImageT> image);

typedef SdFreeNative = Void Function(Pointer<Void> ctx);
typedef SdFreeDart = void Function(Pointer<Void> ctx);

typedef SdGetErrorNative = Pointer<Utf8> Function();
typedef SdGetErrorDart = Pointer<Utf8> Function();

/// FFI bindings to the native sd_wrapper library.
///
/// This class loads the platform-specific shared library and provides
/// Dart-callable wrappers for all sd_wrapper.h functions.
class SdFfi {
  late final DynamicLibrary _lib;
  late final SdInitDart sdInit;
  late final SdSetPhotomakerDart sdSetPhotomaker;
  late final SdSetReferenceImagesDart sdSetReferenceImages;
  late final SdTxt2imgDart sdTxt2img;
  late final SdSaveImageDart sdSaveImage;
  late final SdFreeImageDart sdFreeImage;
  late final SdFreeDart sdFree;
  late final SdGetErrorDart sdGetError;

  SdFfi() {
    _lib = _openLibrary();
    _bindFunctions();
  }

  DynamicLibrary _openLibrary() {
    if (Platform.isWindows) {
      return DynamicLibrary.open('sd_native.dll');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libsd_native.so');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libsd_native.dylib');
    } else if (Platform.isAndroid) {
      return DynamicLibrary.open('libsd_native.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  void _bindFunctions() {
    sdInit = _lib.lookupFunction<SdInitNative, SdInitDart>('sd_init');

    sdSetPhotomaker = _lib
        .lookupFunction<SdSetPhotomakerNative, SdSetPhotomakerDart>(
            'sd_set_photomaker');

    sdSetReferenceImages = _lib
        .lookupFunction<SdSetReferenceImagesNative, SdSetReferenceImagesDart>(
            'sd_set_reference_images');

    sdTxt2img =
        _lib.lookupFunction<SdTxt2imgNative, SdTxt2imgDart>('sd_txt2img');

    sdSaveImage = _lib
        .lookupFunction<SdSaveImageNative, SdSaveImageDart>('sd_save_image');

    sdFreeImage = _lib
        .lookupFunction<SdFreeImageNative, SdFreeImageDart>('sd_free_image');

    sdFree = _lib.lookupFunction<SdFreeNative, SdFreeDart>('sd_free');

    sdGetError = _lib
        .lookupFunction<SdGetErrorNative, SdGetErrorDart>('sd_get_error');
  }
}
