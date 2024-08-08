
#include <xcb/xcb.h>

#include "sane.h"

struct VisualData {
    xcb_visualtype_t *visual;
    u8 visual_depth;
};

struct VisualData xdraw_visual_data_find_argb(const xcb_screen_t *s);
struct VisualData xdraw_visual_data_find_default(const xcb_screen_t *s);
