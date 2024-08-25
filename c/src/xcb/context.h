#ifndef TERRA_XCB_CONTEXT_H
#define TERRA_XCB_CONTEXT_H

#include <xcb/xcb.h>
#include <xcb/xcb_keysyms.h>
#include <xcb/xcb_cursor.h>

// #include <ev.h>

#include <lua.h>

#include "sane.h"

// TODO: organize these properly
struct XcbContext {
    lua_State *L;

    struct xcb_connection_t *connection;
    // TODO: the screen seems to hold information about width in px and mm.
    // Use this information to figure out the dpi of each screen
    struct xcb_screen_t *screen;

    struct xkb_context *xkb_ctx;
    struct xkb_state *xkb_state;

    xcb_visualtype_t *visual;
    u8 visual_depth;
    i32 default_screen_number;
    xcb_colormap_t default_colormap_id;

    // keyboard support
    xcb_key_symbols_t *keysyms;

    // cursor support
    xcb_cursor_context_t *cursor_ctx;
    xcb_cursor_t current_cursor;

    xcb_window_t gc_window;
    xcb_gcontext_t default_gc_id;

#ifdef DEBUG
    struct xcb_errors_context_t *xcb_error_ctx;
#endif
};


#endif
