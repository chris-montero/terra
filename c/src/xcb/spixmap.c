
#include <lua.h>
#include <lauxlib.h>

#include <xcb/xcb.h>

#include "lhelp.h"

#include "xcb/xlhelp.h"
#include "xcb/context.h"

int luaH_spixmap_create(lua_State *L)
{
    struct XcbContext *xc = xlhelp_check_xcb_ctx(L, 1);
    u16 width = luaL_checkint(L, 2);
    u16 height = luaL_checkint(L, 3);

    xcb_pixmap_t pixmap_id = xcb_generate_id(xc->connection);
    xcb_create_pixmap(
        xc->connection,
        xc->visual_depth,
        pixmap_id,
        xc->screen->root, // drawable to get the screen from
        width,
        height
    );

    xlhelp_push_id(L, pixmap_id);

    return 1;
}

int luaH_spixmap_draw_portion_to_window(lua_State *L)
{
    struct XcbContext *xc = xlhelp_check_xcb_ctx(L, 1);
    xcb_pixmap_t pix_id = (xcb_pixmap_t)xlhelp_check_id(L, 2);
    xcb_window_t win_id = (xcb_window_t)xlhelp_check_id(L, 3);

    u16 x = luaL_checkinteger(L, 4);
    u16 y = luaL_checkinteger(L, 5);
    u16 width = luaL_checkinteger(L, 6);
    u16 height = luaL_checkinteger(L, 7);

    xcb_copy_area(
        xc->connection,
        pix_id,
        win_id,
        xc->default_gc_id, // do we even need gcs in x anymore?
        x, x,
        y, y,
        width, height
    );

    return 0;
}

int luaH_spixmap_destroy(lua_State *L)
{
    struct XcbContext *xc = xlhelp_check_xcb_ctx(L, 1);
    xcb_pixmap_t pix_id = (xcb_pixmap_t)xlhelp_check_id(L, 2);
    xcb_free_pixmap(xc->connection, pix_id);
    return 0;
}

static const struct luaL_Reg lib_spixmap[] = {
    { "create", luaH_spixmap_create },
    { "draw_portion_to_window", luaH_spixmap_draw_portion_to_window },
    { "destroy", luaH_spixmap_destroy },
    { NULL, NULL }
};

int luaopen_terra_platforms_xcb_spixmap(lua_State *L)
{
    luaL_newlib(L, lib_spixmap);
    return 1;
}

