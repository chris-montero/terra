
#include <xcb/xcb.h>

#include "application.h"
#include "sane.h"

xcb_window_t terra_window_xcb_create(struct Application *ap, i16 x, i16 y, u16 width, u16 height, u8 override_redirect);
void terra_window_xcb_change_cursor(struct Application *ap, xcb_window_t x_window_id, char *cursor_str);
void terra_window_xcb_set_geometry_request(struct Application *ap, xcb_window_t x_window_id, i16 x, i16 y, u16 width, u16 height);
void terra_window_xcb_set_sizes_request(struct Application *ap, xcb_window_t x_window_id, u16 width, u16 height);
void terra_window_xcb_set_coordinates_request(struct Application *ap, xcb_window_t x_window_id, i16 x, i16 y);
void terra_window_xcb_map_request(struct Application *ap, xcb_window_t x_window_id);
void terra_window_xcb_unmap(struct Application *ap, xcb_window_t x_window_id);
void terra_window_xcb_destroy(struct Application *ap, xcb_window_t x_window_id);
