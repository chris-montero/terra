#ifndef TERRA_APPLICATION_H
#define TERRA_APPLICATION_H

#include <xcb/xcb.h>
#include <xcb/xcb_keysyms.h>
#include <xcb/xcb_cursor.h>

#include <ev.h>

#include <lua.h>

#include "sane.h"

// TODO: organize these properly
// TODO: rename this to "TerraData"
struct Application {
    lua_State *L;
    struct ev_loop *main_loop;

    struct ev_timer frame_timer;
    ev_tstamp wm_start;
    ev_tstamp last_frame_timestamp;

    // struct xcb_connection_t *client_connection;
    struct xcb_connection_t *connection;
    // TODO: the screen seems to hold information about width in px and mm.
    // Use this information to figure out the dpi of each screen
    // TODO: shouldn't we have more screens here? Implement multiple monitor support.
    struct xcb_screen_t *screen;

    struct xkb_context *xkb_ctx;
    struct xkb_state *xkb_state;
    // TODO: do I need all 4 of these?
    // u8 xkb_update_pending; // boolean
    // u8 xkb_reload_keymap; // boolean
    // u8 xkb_map_changed; // boolean
    // u8 xkb_group_changed; // boolean

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
