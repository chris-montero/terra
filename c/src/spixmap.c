
#include <xcb/xcb.h>

#include <lua.h>
#include <lauxlib.h>

#include "lhelp.h"

int luaH_spixmap_create(lua_State *L)
{
    struct Application *ap = lhelp_check_app(L, 1);
    u16 width = luaL_checkint(L, 2);
    u16 height = luaL_checkint(L, 3);

    xcb_pixmap_t pixmap_id = xcb_generate_id(ap->connection);
    xcb_create_pixmap(
        ap->connection,
        ap->visual_depth,
        pixmap_id,
        ap->screen->root, // drawable to get the screen from
        width,
        height
    );

    lhelp_push_id(L, pixmap_id);

    return 1;
}

int luaH_spixmap_draw_portion_to_window(lua_State *L)
{
    struct Application *ap = lhelp_check_app(L, 1);
    xcb_pixmap_t pix_id = (xcb_pixmap_t)lhelp_check_id(L, 2);
    xcb_window_t win_id = (xcb_window_t)lhelp_check_id(L, 3);

    u16 x = luaL_checkinteger(L, 4);
    u16 y = luaL_checkinteger(L, 5);
    u16 width = luaL_checkinteger(L, 6);
    u16 height = luaL_checkinteger(L, 7);

    xcb_copy_area(
        ap->connection,
        pix_id,
        win_id,
        ap->default_gc_id, // do we even need gcs in x anymore?
        x, x,
        y, y,
        width, height
    );

    return 0;
}

int luaH_spixmap_destroy(lua_State *L)
{
    struct Application *ap = lhelp_check_app(L, 1);
    xcb_pixmap_t pix_id = (xcb_pixmap_t)lhelp_check_id(L, 2);
    xcb_free_pixmap(ap->connection, pix_id);
    return 0;
}

static const struct luaL_Reg lib_spixmap[] = {
    { "create", luaH_spixmap_create },
    { "draw_portion_to_window", luaH_spixmap_draw_portion_to_window },
    { "destroy", luaH_spixmap_destroy },
    { NULL, NULL }
};

int luaopen_terra_internal_spixmap(lua_State *L)
{
    luaL_newlib(L, lib_spixmap);
    return 1;
}



