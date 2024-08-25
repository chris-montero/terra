#ifndef TERRA_LHELP_H
#define TERRA_LHELP_H

#include <lua.h>
#include <lauxlib.h>

#include "sane.h"

// from lua5.2. In spite of the fact that we use luajit, which defines these
// macros, we use luarocks to compile the project, which uses lua5.1's
// headers. What this means is that we have to define these ourselves to 
// ensure compatibility with lua5.1.
void luaL_setfuncs(lua_State *L, const luaL_Reg *l, int nup);
#define luaL_newlibtable(L, l) \
	lua_createtable(L, 0, sizeof(l)/sizeof((l)[0]) - 1)
#define luaL_newlib(L, l)	(luaL_newlibtable(L, l), luaL_setfuncs(L, l, 0))

void lhelp_dump_stack(lua_State *L);
int lhelp_function_on_runtime_error(lua_State *L);

void lhelp_set_bool(lua_State *L, char *name, bool b);
void lhelp_set_int(lua_State *L, char *name, int i);
void lhelp_set_string(lua_State *L, char *name, char *value);

#endif
