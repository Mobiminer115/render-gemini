#import <Foundation/Foundation.h>
#include <sys/sysctl.h>
#include <mach/mach.h>
#include <os/proc.h>
#include <stdlib.h>
#include <stdio.h>
#include <dlfcn.h>
#include "../include/ios_gemini_tier.h"

static gemini_device_tier_t g_device_tier = GEMINI_TIER_2_MID_RAM;
static int g_max_tex_size = 8192;
static uint64_t g_physical_ram_mb = 2048;
static uint32_t g_frame_counter = 0;
static int g_initialized = 0;

// Khai bao ham flush noi bo cua GL4ES neu co
extern void gl4es_glFlush(void) __attribute__((weak));

static void set_env_default(const char *key, const char *val) {
    if (getenv(key) == NULL) {
        setenv(key, val, 1);
    }
}

static uint64_t query_physical_ram_mb(void) {
    uint64_t memsize = 0;
    size_t len = sizeof(memsize);
    if (sysctlbyname("hw.memsize", &memsize, &len, NULL, 0) == 0 && memsize > 0) {
        return memsize / (1024ULL * 1024ULL);
    }
    return 2048;
}

static void resolve_ios_gles_backend(void) {
    if (getenv("LIBGL_GLES") != NULL) return;

    // Uu tien MetalANGLE neu Amethyst-iOS co nhung san, neu khong dung OpenGLES.framework goc cua Apple
    const char *candidates[] = {
        "@rpath/MetalANGLE.framework/MetalANGLE",
        "@rpath/libGLESv2.dylib",
        "/System/Library/Frameworks/OpenGLES.framework/OpenGLES"
    };

    for (size_t i = 0; i < sizeof(candidates) / sizeof(candidates[0]); ++i) {
        void *handle = dlopen(candidates[i], RTLD_LAZY | RTLD_NOLOAD);
        if (handle) {
            setenv("LIBGL_GLES", candidates[i], 1);
            dlclose(handle);
            return;
        }
    }
    setenv("LIBGL_GLES", "/System/Library/Frameworks/OpenGLES.framework/OpenGLES", 1);
}

// Chay tu dong ngay khi Amethyst-iOS dlopen() file .dylib nay (truoc khi GL4ES init)
__attribute__((constructor(101)))
void gemini_ios_early_init(void) {
    if (g_initialized) return;
    g_initialized = 1;

    g_physical_ram_mb = query_physical_ram_mb();
    resolve_ios_gles_backend();

    if (g_physical_ram_mb <= 2200) {
        // Tier 1: iPhone 6s Plus / 6s / SE1 / 7 / 8 (2GB RAM)
        g_device_tier = GEMINI_TIER_1_LOW_RAM;
        g_max_tex_size = 4096;

        set_env_default("LIBGL_ES", "2");
        set_env_default("LIBGL_VBO", "1");
        set_env_default("LIBGL_MERGED", "1");
        set_env_default("LIBGL_BEGINEND", "1");
        set_env_default("LIBGL_DEEPZ", "1");
        set_env_default("LIBGL_NOERROR", "1");
        set_env_default("LIBGL_FAST_MATH", "1");
        set_env_default("LIBGL_NPOT", "2");
        set_env_default("LIBGL_SILENTSTUB", "1");
        set_env_default("LIBGL_NOHIGHP", "0");
    } else if (g_physical_ram_mb <= 4200) {
        // Tier 2: iPhone 7 Plus / 8 Plus / X / XR / XS / 11 (3GB - 4GB RAM)
        g_device_tier = GEMINI_TIER_2_MID_RAM;
        g_max_tex_size = 8192;

        set_env_default("LIBGL_ES", "2");
        set_env_default("LIBGL_VBO", "1");
        set_env_default("LIBGL_MERGED", "1");
        set_env_default("LIBGL_BEGINEND", "1");
        set_env_default("LIBGL_DEEPZ", "1");
        set_env_default("LIBGL_NOERROR", "1");
        set_env_default("LIBGL_FAST_MATH", "1");
        set_env_default("LIBGL_NPOT", "2");
        set_env_default("LIBGL_SILENTSTUB", "1");
    } else {
        // Tier 3: iPhone 12 Pro -> iPhone 16 Pro Max (>= 6GB RAM)
        g_device_tier = GEMINI_TIER_3_HIGH_RAM;
        g_max_tex_size = 16384;

        set_env_default("LIBGL_ES", "2");
        set_env_default("LIBGL_VBO", "1");
        set_env_default("LIBGL_MERGED", "1");
        set_env_default("LIBGL_BEGINEND", "1");
        set_env_default("LIBGL_DEEPZ", "1");
        set_env_default("LIBGL_NOERROR", "1");
        set_env_default("LIBGL_FAST_MATH", "1");
        set_env_default("LIBGL_NPOT", "2");
        set_env_default("LIBGL_SILENTSTUB", "1");
    }

    fprintf(stderr, "[GeminiGL4ES] Detected RAM: %llu MB -> Tier %d (MaxTexSize: %d)\n",
            g_physical_ram_mb, (int)g_device_tier, g_max_tex_size);
}

int gemini_ios_get_device_tier(void) {
    if (!g_initialized) gemini_ios_early_init();
    return (int)g_device_tier;
}

int gemini_ios_get_max_tex_size(void) {
    if (!g_initialized) gemini_ios_early_init();
    return g_max_tex_size;
}

// Goi dinh ky tai ranh gioi frame de canh gac ngưỡng Jetsam tren iPhone 6s Plus
void gemini_ios_frame_tick(void) {
    g_frame_counter++;
    // Kiem tra moi 180 frames (~3 giay o 60FPS) de khong gay overhead CPU
    if ((g_frame_counter % 180) != 0) return;

    if (@available(iOS 13.0, *)) {
        size_t avail_bytes = os_proc_available_memory();
        if (avail_bytes > 0) {
            size_t avail_mb = avail_bytes / (1024 * 1024);
            size_t threshold_mb = (g_device_tier == GEMINI_TIER_1_LOW_RAM) ? 96 : 128;
            if (avail_mb < threshold_mb) {
                // Ep giai phong command buffer do hoa truoc khi Jetsam kill tien trinh
                if (gl4es_glFlush) {
                    gl4es_glFlush();
                }
            }
        }
    }
}
