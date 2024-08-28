
#include <lua.h>
#include <lauxlib.h>

#include <cairo/cairo-xcb.h>

#include "lhelp.h"

#include "xcb/xlhelp.h"
#include "xcb/context.h"

int luaH_scairo_surface_create_from_pixmap(lua_State *L)
{
    struct XcbContext *xc = xlhelp_check_xcb_ctx(L, 1);
    xcb_pixmap_t pixmap_id = (xcb_pixmap_t)xlhelp_check_id(L, 2);
    u16 width = luaL_checkinteger(L, 3);
    u16 height = luaL_checkinteger(L, 4);

    cairo_surface_t *cairo_surface = cairo_xcb_surface_create(
        xc->connection,
        pixmap_id,
        xc->visual,
        width,
        height
    );

    // push the pointer directly as a lua number. TODO: is this safe?
    // Also: http://lua-users.org/wiki/LightUserData says 
    // "Light userdata are intended to store C pointers in Lua (note: 
    // Lua numbers may or may not be suitable for this purpose depending 
    // on the data types on the platform)."
    // My problem was that I couldn't give lgi a lightuserdata and have
    // it understand it was a pointer, but it worked if I just gave it
    // a number, hence the use of an integer here.
    lua_pushinteger(L, (u64)cairo_surface);
    return 1;
}

int luaH_scairo_surface_set_pixmap(lua_State *L)
{
    cairo_surface_t *cairo_surface = (cairo_surface_t *) lua_tointeger(L, 1);
    xcb_pixmap_t pixmap_id = (xcb_pixmap_t)xlhelp_check_id(L, 2);
    u16 width = luaL_checkinteger(L, 3);
    u16 height = luaL_checkinteger(L, 4);

    cairo_xcb_surface_set_drawable(cairo_surface, pixmap_id, width, height);

    return 0;
}

int luaH_scairo_surface_destroy(lua_State *L)
{
    cairo_surface_t *cairo_surface = (cairo_surface_t *) lua_tointeger(L, 1);
    cairo_surface_finish(cairo_surface);
    cairo_surface_destroy(cairo_surface);
    return 0;
}

static const struct luaL_Reg lib_scairo[] = {
    { "create_from_pixmap", luaH_scairo_surface_create_from_pixmap },
    { "set_pixmap", luaH_scairo_surface_set_pixmap },
    { "destroy", luaH_scairo_surface_destroy },
    { NULL, NULL }
};

int luaopen_terra_platforms_xcb_scairo(lua_State *L)
{
    luaL_newlib(L, lib_scairo);
    return 1;
}

