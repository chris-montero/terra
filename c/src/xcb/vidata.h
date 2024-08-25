#ifndef TERRA_XCB_VIDATA_H
#define TERRA_XCB_VIDATA_H

#include <xcb/xcb.h>

#include "sane.h"

struct VisualData {
    xcb_visualtype_t *visual;
    u8 visual_depth;
};

bool vidata_is_invalid(struct VisualData vidata);
struct VisualData vidata_find_argb(const xcb_screen_t *s);
struct VisualData vidata_find_default(const xcb_screen_t *s);

#endif
