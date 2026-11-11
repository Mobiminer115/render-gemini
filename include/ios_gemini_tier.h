#ifndef IOS_GEMINI_TIER_H
#define IOS_GEMINI_TIER_H

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    GEMINI_TIER_1_LOW_RAM = 1,   // iPhone 6s Plus, 6s, SE1, 7, 8 (<= 2GB RAM - Apple A9-A11)
    GEMINI_TIER_2_MID_RAM = 2,   // iPhone 7+, 8+, X, XR, XS, 11 (3GB - 4GB RAM)
    GEMINI_TIER_3_HIGH_RAM = 3   // iPhone 12 Pro -> 16 Pro Max (>= 6GB RAM)
} gemini_device_tier_t;

void gemini_ios_early_init(void);
int gemini_ios_get_device_tier(void);
int gemini_ios_get_max_tex_size(void);
void gemini_ios_frame_tick(void);

#ifdef __cplusplus
}
#endif

#endif // IOS_GEMINI_TIER_H
