/**
 * Thin C wrapper around stable-diffusion.cpp's C API.
 *
 * This file bridges the Flutter FFI layer to stable-diffusion.cpp.
 * It handles model loading, txt2img/img2img generation, PhotoMaker setup,
 * and image I/O.
 *
 * Build: Compiled as a shared library (.dll/.so/.dylib) per platform.
 * Dependencies: stable-diffusion.cpp (linked statically or as submodule).
 *
 * When stable-diffusion.cpp is not yet linked, this provides stub
 * implementations that return appropriate error codes.
 */

#include "sd_wrapper.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

static char g_error_msg[1024] = "";

static void set_error(const char* msg) {
    strncpy(g_error_msg, msg, sizeof(g_error_msg) - 1);
    g_error_msg[sizeof(g_error_msg) - 1] = '\0';
}

/*
 * When stable-diffusion.cpp is linked, replace these stubs with:
 *
 *   #include "stable-diffusion.h"
 *
 * and implement each function using sd_ctx_t from the library.
 */

typedef struct {
    char model_path[512];
    char photomaker_path[512];
    char* ref_image_paths[4];
    int num_ref_images;
    int n_threads;
    bool has_photomaker;
} sd_internal_ctx_t;

SD_API sd_context_t sd_init(
    const char* model_path,
    const char* vae_path,
    int n_threads
) {
    if (!model_path) {
        set_error("model_path is NULL");
        return NULL;
    }

    sd_internal_ctx_t* ctx = (sd_internal_ctx_t*)calloc(1, sizeof(sd_internal_ctx_t));
    if (!ctx) {
        set_error("Failed to allocate context");
        return NULL;
    }

    strncpy(ctx->model_path, model_path, sizeof(ctx->model_path) - 1);
    ctx->n_threads = n_threads > 0 ? n_threads : 4;
    ctx->has_photomaker = false;

    /*
     * TODO: Replace with actual stable-diffusion.cpp initialization:
     *
     *   sd_ctx_t* sd_ctx = new_sd_ctx(
     *       model_path,
     *       "",               // clip_l_path
     *       "",               // t5xxl_path
     *       "",               // diffusion_model_path
     *       vae_path ? vae_path : "",
     *       "",               // taesd_path
     *       "",               // controlnet_path
     *       "",               // lora_model_dir
     *       "",               // embed_dir
     *       "",               // stacked_id_embed_dir
     *       false,            // vae_decode_only
     *       true,             // vae_tiling
     *       false,            // free_params_immediately
     *       n_threads,
     *       SD_TYPE_COUNT,    // wtype (auto)
     *       STD_DEFAULT_RNG,  // rng_type
     *       DEFAULT_SCHEDULE, // schedule
     *       false             // keep_clip_on_cpu
     *   );
     */

    return (sd_context_t)ctx;
}

SD_API bool sd_set_photomaker(sd_context_t ctx, const char* photomaker_path) {
    if (!ctx || !photomaker_path) {
        set_error("Invalid arguments");
        return false;
    }

    sd_internal_ctx_t* internal = (sd_internal_ctx_t*)ctx;
    strncpy(internal->photomaker_path, photomaker_path,
            sizeof(internal->photomaker_path) - 1);
    internal->has_photomaker = true;
    return true;
}

SD_API bool sd_set_reference_images(
    sd_context_t ctx,
    const char** image_paths,
    int num_images
) {
    if (!ctx || !image_paths || num_images < 1 || num_images > 4) {
        set_error("Invalid arguments");
        return false;
    }

    sd_internal_ctx_t* internal = (sd_internal_ctx_t*)ctx;

    for (int i = 0; i < internal->num_ref_images; i++) {
        free(internal->ref_image_paths[i]);
        internal->ref_image_paths[i] = NULL;
    }

    internal->num_ref_images = num_images;
    for (int i = 0; i < num_images; i++) {
        internal->ref_image_paths[i] = strdup(image_paths[i]);
    }

    return true;
}

SD_API sd_image_t* sd_txt2img(
    sd_context_t ctx,
    const char* prompt,
    const char* negative_prompt,
    sd_generation_params_t params,
    sd_progress_callback_t progress_cb,
    void* userdata
) {
    if (!ctx || !prompt) {
        set_error("Invalid arguments");
        return NULL;
    }

    /*
     * TODO: Replace with actual stable-diffusion.cpp txt2img call:
     *
     *   sd_image_t* results = txt2img(
     *       sd_ctx,
     *       prompt,
     *       negative_prompt ? negative_prompt : "",
     *       params.clip_skip,
     *       params.cfg_scale,
     *       params.width,
     *       params.height,
     *       (enum sample_method_t)params.sample_method,
     *       params.steps,
     *       params.seed,
     *       params.batch_count,
     *       NULL,    // control_image
     *       0.0f,    // control_strength
     *       0.0f,    // style_strength (PhotoMaker)
     *       false,   // normalize_input
     *       ""       // input_id_images_path (PhotoMaker)
     *   );
     *
     *   // Wrap result into our sd_image_t format
     */

    /* Stub: simulate progress */
    if (progress_cb) {
        for (int step = 0; step < params.steps; step++) {
            progress_cb(step + 1, params.steps, userdata);
        }
    }

    set_error("Native SD library not yet linked - stub implementation");
    return NULL;
}

SD_API sd_image_t* sd_img2img(
    sd_context_t ctx,
    sd_image_t* init_image,
    const char* prompt,
    const char* negative_prompt,
    float strength,
    sd_generation_params_t params,
    sd_progress_callback_t progress_cb,
    void* userdata
) {
    if (!ctx || !init_image || !prompt) {
        set_error("Invalid arguments");
        return NULL;
    }

    /* TODO: Replace with actual img2img call */
    set_error("img2img not yet implemented");
    return NULL;
}

SD_API bool sd_save_image(sd_image_t* image, const char* output_path) {
    if (!image || !output_path || !image->data) {
        set_error("Invalid arguments");
        return false;
    }

    /* TODO: Use stb_image_write or sd.cpp's built-in PNG writer */
    set_error("save_image not yet implemented");
    return false;
}

SD_API sd_image_t* sd_load_image(const char* path) {
    if (!path) {
        set_error("path is NULL");
        return NULL;
    }

    /* TODO: Use stb_image to load */
    set_error("load_image not yet implemented");
    return NULL;
}

SD_API void sd_free_image(sd_image_t* image) {
    if (image) {
        free(image->data);
        free(image);
    }
}

SD_API void sd_free(sd_context_t ctx) {
    if (!ctx) return;

    sd_internal_ctx_t* internal = (sd_internal_ctx_t*)ctx;
    for (int i = 0; i < internal->num_ref_images; i++) {
        free(internal->ref_image_paths[i]);
    }

    /* TODO: Also call free_sd_ctx(sd_ctx) */
    free(internal);
}

SD_API const char* sd_get_error(void) {
    return g_error_msg;
}
