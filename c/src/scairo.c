
#include <cairo/cairo-xcb.h>

#include <lua.h>
#include <lauxlib.h>

#include "lhelp.h"

int luaH_scairo_surface_create_from_pixmap(lua_State *L)
{
    struct Application *ap = lhelp_check_app(L, 1);
    xcb_pixmap_t pixmap_id = (xcb_pixmap_t)lhelp_check_id(L, 2);
    u16 width = luaL_checkinteger(L, 3);
    u16 height = luaL_checkinteger(L, 4);

    cairo_surface_t *cairo_surface = cairo_xcb_surface_create(
        ap->connection,
        pixmap_id,
        ap->visual,
        width,
        height
    );

    // push the pointer directly as a lua number. TODO: is this safe?
    lua_pushinteger(L, (u64)cairo_surface);
    return 1;
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
    { "destroy", luaH_scairo_surface_destroy },
    { NULL, NULL }
};

int luaopen_terra_internal_scairo(lua_State *L)
{
    luaL_newlib(L, lib_scairo);
    return 1;
}

