#ifndef TERRA_XCB_XUTIL_H
#define TERRA_XCB_XUTIL_H

#include <xcb/xcb.h>

xcb_keycode_t xutil_string_to_keycode(const char *str);
xcb_keycode_t *xutil_xcb_keysym_to_keycode(xcb_keysym_t keysym);
xcb_keysym_t xutil_xcb_keycode_to_keysym(xcb_keycode_t keycode);

void xutil_xerror_handle(xcb_generic_error_t *error);

#endif
