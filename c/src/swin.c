
#include <xcb/xcb.h>

#include <lua.h>
#include <lauxlib.h>

#include "windows/xcb.h"
#include "lhelp.h"
// #include "click.h"
// #include "key.h"

int luaH_swin_create(lua_State *L)
{
    struct Application *ap = lhelp_check_app(L, 1);
    // TODO: maybe check that these don't go over bounds
    i16 x = luaL_checkint(L, 2);
    i16 y = luaL_checkint(L, 3);
    u16 width = luaL_checkint(L, 4);
    u16 height = luaL_checkint(L, 5);
    luaL_checktype(L, 6, LUA_TBOOLEAN);
    u8 override_redirect = lua_toboolean(L, 6);
    printf("override_redirect: %b\n", override_redirect);

    // these can never be 0
    if (width == 0) width = 1;
    if (height == 0) height = 1;

    // TODO: make this platform independent
    xcb_window_t x_window_id = terra_window_xcb_create(ap, x, y, width, height, override_redirect);
    lhelp_push_id(L, x_window_id);
    xcb_flush(ap->connection);
    return 1;
}

int luaH_swin_map_request(lua_State *L) {
    struct Application *ap = lhelp_check_app(L, 1);
    xcb_window_t x_win_id = (xcb_window_t)lhelp_check_id(L, 2);
    terra_window_xcb_map_request(ap, x_win_id);
    xcb_flush(ap->connection);
    return 0;
}

int luaH_swin_unmap(lua_State *L) {
    struct Application *ap = lhelp_check_app(L, 1);
    xcb_window_t x_win_id = (xcb_window_t)lhelp_check_id(L, 2);
    terra_window_xcb_unmap(ap, x_win_id);
    return 0;
}

int luaH_swin_set_geometry_request(lua_State *L) {
    struct Application *ap = lhelp_check_app(L, 1);
    xcb_window_t x_win_id = (xcb_window_t)lhelp_check_id(L, 2);

    // TODO: maybe check that these don't go over bounds
    i16 x = (i16)luaL_checkint(L, 3);
    i16 y = (i16)luaL_checkint(L, 4);
    u16 width = (u16)luaL_checkint(L, 5);
    u16 height = (u16)luaL_checkint(L, 6);

    terra_window_xcb_set_geometry_request(ap, x_win_id, x, y, width, height);
    return 0;
}

int luaH_swin_set_coordinates_request(lua_State *L) {
    struct Application *ap = lhelp_check_app(L, 1);
    xcb_window_t x_win_id = (xcb_window_t)lhelp_check_id(L, 2);

    // TODO: maybe check that these don't go over bounds
    i16 x = (i16)luaL_checkint(L, 3);
    i16 y = (i16)luaL_checkint(L, 4);

    terra_window_xcb_set_coordinates_request(ap, x_win_id, x, y);
    return 0;
}

int luaH_swin_set_sizes_request(lua_State *L) {
    struct Application *ap = lhelp_check_app(L, 1);
    xcb_window_t x_win_id = (xcb_window_t)lhelp_check_id(L, 2);

    // TODO: maybe check that these don't go over bounds
    u16 width = (u16)luaL_checkint(L, 3);
    u16 height = (u16)luaL_checkint(L, 4);

    terra_window_xcb_set_sizes_request(ap, x_win_id, width, height);
    return 0;
}

int luaH_swin_destroy(lua_State *L)
{
    struct Application *ap = lhelp_check_app(L, 1);
    xcb_window_t x_win_id = (xcb_window_t)lhelp_check_id(L, 2);
    terra_window_xcb_destroy(ap, x_win_id);
    return 0;
}

// TODO: use properties for this (I think ICCCM had something for this)
// int luaH_swin_focus_request(lua_State *L)
// {
//     xcb_window_t x_win_id = (xcb_window_t)lhelp_check_id(L, 1);
//     window_set_focus(x_win_id);
//     return 0;
// }


// // TODO: move this documentation somewhere else, or maybe just put a 
// // manual together and also include this.
// // you should be able to use this from the lua side as such:
// // `swin.subscribe_key(<window_id>, <key_id>)`
// // where <key_id> is a table of the form:
// // {
// //      key: string,
// //      is_press: TRUE (for press) or FALSE (for release),
// //      modifiers : number (which is a 16 bit bitmask denoting which modifiers have to be pressed for this key to fire)
// // }
// int luaH_swin_subscribe_key(lua_State *L)
// {
//     xcb_window_t x_win_id = (xcb_window_t)lhelp_check_id(L, 1);
//     struct Key k = lhelp_key_from_table(L); // expects table to be on top
//     window_subscribe_key(x_win_id, k);
//
//     // printf("Subscribing Key on window %d:\n", win);
//     // printf("\tkeycode: %d\n", k.keycode);
//     // printf("\tkey_event: %d\n", k.key_event);
//     // printf("\tmodifiers: %b\n", k.modifiers);
//
//     return 0;
// }
//
// int luaH_swin_unsubscribe_key(lua_State *L)
// {
//     xcb_window_t x_win_id = (xcb_window_t)lhelp_check_id(L, 1);
//     // TODO: maybe rework this into `lhelp_check_key`
//     struct Key k = lhelp_key_from_table(L); // expects table to be on top
//     window_unsubscribe_key(x_win_id, k);
//     return 0;
// }
//
// int luaH_swin_subscribe_click(lua_State *L)
// {
//     xcb_window_t x_win_id = (xcb_window_t)lhelp_check_id(L, 1);
//     struct Click c = lhelp_click_from_table(L); // expects table to be on top
//     window_subscribe_click(x_win_id, c);
//     return 0;
// }
//
// int luaH_swin_unsubscribe_click(lua_State *L)
// {
//     xcb_window_t x_win_id = (xcb_window_t)lhelp_check_id(L, 1);
//     // TODO: maybe rework this into `lhelp_check_click`
//     struct Click c = lhelp_click_from_table(L); // expects table to be on top
//     window_unsubscribe_click(x_win_id, c);
//     return 0;
// }
//
// int luaH_swin_grab_pointer(lua_State *L)
// {
//     xcb_window_t x_win_id = (xcb_window_t)lhelp_check_id(L, 1);
//     const xcb_event_mask_t event_mask = (xcb_event_mask_t)luaL_checkinteger(L, 2);
//     window_grab_pointer(x_win_id, event_mask);
//     return 0;
// }
//
// int luaH_swin_ungrab_pointer(lua_State *L)
// {
//     window_ungrab_pointer();
//     return 0;
// }
//
// int luaH_swin_window_stack_above(lua_State *L)
// {
//     xcb_window_t below = (xcb_window_t)lhelp_check_id(L, 1);
//     xcb_window_t win_id = (xcb_window_t)lhelp_check_id(L, 2);
//
//     window_stack_above(below, win_id);
//     return 0;
// }

static const struct luaL_Reg lib_swin[] = {
    { "create", luaH_swin_create },
    { "destroy", luaH_swin_destroy },
    { "map_request", luaH_swin_map_request },
    { "unmap", luaH_swin_unmap },
    { "set_geometry_request", luaH_swin_set_geometry_request },
    { "set_coordinates_request", luaH_swin_set_coordinates_request },
    { "set_sizes_request", luaH_swin_set_sizes_request },
    // { "change_event_mask", luaH_swin_change_event_mask },
    // { "set_focus", luaH_swin_set_focus },
    // { "map_request", luaH_swin_map_request },
    // { "subscribe_key", luaH_swin_subscribe_key },
    // { "unsubscribe_key", luaH_swin_unsubscribe_key },
    // { "subscribe_click", luaH_swin_subscribe_click },
    // { "unsubscribe_click", luaH_swin_unsubscribe_click },
    // { "grab_pointer", luaH_swin_grab_pointer },
    // { "ungrab_pointer", luaH_swin_ungrab_pointer },
    // { "stack_above", luaH_swin_window_stack_above },
    { NULL, NULL }
};

int luaopen_terra_internal_swin(lua_State *L)
{
    luaL_newlib(L, lib_swin);
    return 1;
}


