#ifndef TERRA_XCB_WINDOW_H
#define TERRA_XCB_WINDOW_H

#include <xcb/xcb.h>

#include "xcb/context.h"
#include "sane.h"

xcb_window_t terra_xcb_window_create(struct XcbContext *xc, i16 x, i16 y, u16 width, u16 height, u8 override_redirect);
void terra_xcb_window_change_cursor(struct XcbContext *xc, xcb_window_t x_window_id, char *cursor_str);
void terra_xcb_window_set_geometry_request(struct XcbContext *xc, xcb_window_t x_window_id, i16 x, i16 y, u16 width, u16 height);
void terra_xcb_window_set_sizes_request(struct XcbContext *xc, xcb_window_t x_window_id, u16 width, u16 height);
void terra_xcb_window_set_coordinates_request(struct XcbContext *xc, xcb_window_t x_window_id, i16 x, i16 y);
void terra_xcb_window_map_request(struct XcbContext *xc, xcb_window_t x_window_id);
void terra_xcb_window_unmap(struct XcbContext *xc, xcb_window_t x_window_id);
void terra_xcb_window_destroy(struct XcbContext *xc, xcb_window_t x_window_id);

#endif
