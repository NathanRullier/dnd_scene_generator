#ifndef SD_WRAPPER_H
#define SD_WRAPPER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef _WIN32
#define SD_API __declspec(dllexport)
#else
#define SD_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef void* sd_context_t;

typedef struct {
    int width;
    int height;
    int steps;
    float cfg_scale;
    int64_t seed;
    int sample_method;     // 0=euler_a, 1=euler, 2=heun, 3=dpm2, 4=dpm++2s_a, 5=dpm++2m, 6=dpm++2mv2, 7=lcm
    int schedule;          // 0=default, 1=discrete, 2=karras
    int batch_count;
    int clip_skip;
} sd_generation_params_t;

typedef struct {
    uint8_t* data;
    int width;
    int height;
    int channels;
} sd_image_t;

typedef void (*sd_progress_callback_t)(int step, int total_steps, void* userdata);

/**
 * Initialize a stable diffusion context from a model file.
 *
 * @param model_path Path to the model file (.gguf, .safetensors, .ckpt)
 * @param vae_path   Optional VAE model path (NULL to use built-in)
 * @param n_threads  Number of CPU threads (-1 for auto)
 * @return           Opaque context handle, or NULL on failure
 */
SD_API sd_context_t sd_init(
    const char* model_path,
    const char* vae_path,
    int n_threads
);

/**
 * Set a PhotoMaker model for character injection (SDXL only).
 *
 * @param ctx              SD context
 * @param photomaker_path  Path to PhotoMaker .safetensors
 * @return                 true on success
 */
SD_API bool sd_set_photomaker(
    sd_context_t ctx,
    const char* photomaker_path
);

/**
 * Set reference images for PhotoMaker.
 *
 * @param ctx          SD context
 * @param image_paths  Array of file paths to reference images
 * @param num_images   Number of images (1-4)
 * @return             true on success
 */
SD_API bool sd_set_reference_images(
    sd_context_t ctx,
    const char** image_paths,
    int num_images
);

/**
 * Generate an image from a text prompt (txt2img).
 *
 * @param ctx              SD context
 * @param prompt           Positive prompt
 * @param negative_prompt  Negative prompt
 * @param params           Generation parameters
 * @param progress_cb      Optional progress callback
 * @param userdata         Userdata passed to callback
 * @return                 Generated image (caller must free with sd_free_image)
 */
SD_API sd_image_t* sd_txt2img(
    sd_context_t ctx,
    const char* prompt,
    const char* negative_prompt,
    sd_generation_params_t params,
    sd_progress_callback_t progress_cb,
    void* userdata
);

/**
 * Generate an image from another image + prompt (img2img).
 *
 * @param ctx              SD context
 * @param init_image       Input image
 * @param prompt           Positive prompt
 * @param negative_prompt  Negative prompt
 * @param strength         Denoising strength (0.0 to 1.0)
 * @param params           Generation parameters
 * @param progress_cb      Optional progress callback
 * @param userdata         Userdata passed to callback
 * @return                 Generated image (caller must free with sd_free_image)
 */
SD_API sd_image_t* sd_img2img(
    sd_context_t ctx,
    sd_image_t* init_image,
    const char* prompt,
    const char* negative_prompt,
    float strength,
    sd_generation_params_t params,
    sd_progress_callback_t progress_cb,
    void* userdata
);

/**
 * Save an image to a file (PNG format).
 *
 * @param image       Image to save
 * @param output_path Output file path (.png)
 * @return            true on success
 */
SD_API bool sd_save_image(sd_image_t* image, const char* output_path);

/**
 * Load an image from a file.
 *
 * @param path  File path
 * @return      Loaded image (caller must free with sd_free_image)
 */
SD_API sd_image_t* sd_load_image(const char* path);

/**
 * Free an image allocated by sd_txt2img, sd_img2img, or sd_load_image.
 */
SD_API void sd_free_image(sd_image_t* image);

/**
 * Free a stable diffusion context.
 */
SD_API void sd_free(sd_context_t ctx);

/**
 * Get the last error message.
 *
 * @return Error string (valid until next API call)
 */
SD_API const char* sd_get_error(void);

#ifdef __cplusplus
}
#endif

#endif /* SD_WRAPPER_H */
