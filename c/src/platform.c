
#include <lua.h>
// #define PLATFORM "xcb" // TODO: parameterize this
//
// int terra_get_platform(lua_State *L)
// {
//     lua_pushstring(L, PLATFORM);
//     return 1;
// }
//
// static const struct luaL_Reg lib_terra_platform[] = {
//
//     { "get", terra_get_platform },
//     { NULL, NULL },
// };
//
// int luaopen_terra_platform(lua_State *L)
// {
//     luaL_newlib(L, lib_terra_platform);
//
//     return 1;
// }

#define PLATFORM "xcb" // TODO: parameterize this

int luaopen_terra_platform(lua_State *L)
{
    lua_pushstring(L, PLATFORM);

    return 1;
}

